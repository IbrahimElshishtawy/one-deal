import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly firebaseProjectId: string;
  private readonly firebaseClientEmail: string;
  private readonly firebasePrivateKey: string;

  constructor(
    private readonly configService: ConfigService,
    @Optional() private readonly prisma?: PrismaService,
  ) {
    this.firebaseProjectId = this.configService.get<string>(
      'FIREBASE_PROJECT_ID',
      '',
    );
    this.firebaseClientEmail = this.configService.get<string>(
      'FIREBASE_CLIENT_EMAIL',
      '',
    );
    this.firebasePrivateKey = this.configService
      .get<string>('FIREBASE_PRIVATE_KEY', '')
      .replace(/\\n/g, '\n');
  }

  private hasRealFcmCredentials(): boolean {
    return (
      !!this.firebaseProjectId &&
      !!this.firebaseClientEmail &&
      !!this.firebasePrivateKey &&
      !this.firebaseClientEmail.startsWith('placeholder') &&
      !this.firebasePrivateKey.startsWith('placeholder')
    );
  }

  /**
   * Registers or updates an FCM device token in PostgreSQL `user_devices`.
   */
  async registerDeviceToken(
    userId: string,
    token: string,
    platform: 'ios' | 'android',
    appVersion?: string,
  ) {
    if (this.prisma?.userDevice) {
      await this.prisma.userDevice.upsert({
        where: {
          uq_user_device_token: {
            userId,
            fcmToken: token,
          },
        },
        update: {
          platform,
          appVersion: appVersion ?? null,
          lastSeenAt: new Date(),
        },
        create: {
          userId,
          fcmToken: token,
          platform,
          appVersion: appVersion ?? null,
        },
      });
    }

    this.logger.log(
      `📲 Registered device token for user ${userId} on platform ${platform}`,
    );
    return { success: true, message: 'Device token registered successfully' };
  }

  /**
   * Persists notification record and dispatches via FCM HTTP v1 API when configured.
   */
  async sendPushNotification(
    targetUserId: string,
    title: string,
    body: string,
    dataPayload: Record<string, string> = {},
  ) {
    if (this.prisma?.notification) {
      await this.prisma.notification
        .create({
          data: {
            userId: targetUserId,
            type: dataPayload.type || 'GENERAL',
            title,
            body,
            payload: dataPayload as any,
          },
        })
        .catch((err) =>
          this.logger.warn(
            `Failed to persist notification row: ${err.message}`,
          ),
        );
    }

    if (!this.hasRealFcmCredentials()) {
      this.logger.log(
        `🔔 [FCM Mock Dispatch] To User: ${targetUserId} | Title: "${title}" | Payload: ${JSON.stringify(dataPayload)}`,
      );
      return { success: true, messageId: `fcm-mock-${Date.now()}` };
    }

    const devices = this.prisma?.userDevice
      ? await this.prisma.userDevice.findMany({
          where: { userId: targetUserId },
          select: { fcmToken: true },
        })
      : [];

    if (devices.length === 0) {
      return { success: true, sentCount: 0 };
    }

    const accessToken = await this.mintGoogleAccessToken();
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${this.firebaseProjectId}/messages:send`;

    const results = await Promise.allSettled(
      devices.map(async ({ fcmToken }) => {
        const res = await fetch(fcmEndpoint, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: fcmToken,
              notification: { title, body },
              data: dataPayload,
            },
          }),
        });
        if (!res.ok) {
          throw new Error(`FCM HTTP ${res.status}`);
        }
        return res.json();
      }),
    );

    const sentCount = results.filter((r) => r.status === 'fulfilled').length;
    return { success: sentCount > 0, sentCount };
  }

  /**
   * Generates a short-lived Google OAuth2 access token from Service Account credentials for FCM HTTP v1.
   */
  private async mintGoogleAccessToken(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    const header = Buffer.from(
      JSON.stringify({ alg: 'RS256', typ: 'JWT' }),
    ).toString('base64url');
    const claimSet = Buffer.from(
      JSON.stringify({
        iss: this.firebaseClientEmail,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
      }),
    ).toString('base64url');

    const unsigned = `${header}.${claimSet}`;
    const signature = crypto
      .createSign('RSA-SHA256')
      .update(unsigned)
      .sign(this.firebasePrivateKey, 'base64url');

    const assertion = `${unsigned}.${signature}`;
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    });

    const tokenJson = (await tokenRes.json()) as { access_token?: string };
    if (!tokenRes.ok || !tokenJson.access_token) {
      throw new Error('Failed to mint Google OAuth2 token for FCM');
    }
    return tokenJson.access_token;
  }
}
