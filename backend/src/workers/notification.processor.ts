import { Injectable, Logger } from '@nestjs/common';
import { NotificationsService } from '../modules/notifications/notifications.service';

export interface PushNotificationJobData {
  targetUserId: string;
  title: string;
  body: string;
  dataPayload?: Record<string, string>;
}

/**
 * NotificationProcessor handles background dispatching of push notifications
 * without blocking critical synchronous API paths (like message posting).
 */
@Injectable()
export class NotificationProcessor {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(private readonly notificationsService: NotificationsService) {}

  async processNotificationJob(
    data: PushNotificationJobData,
  ): Promise<boolean> {
    try {
      this.logger.log(
        `📬 [Worker: Notification] Processing push dispatch to user ${data.targetUserId}...`,
      );
      const result = await this.notificationsService.sendPushNotification(
        data.targetUserId,
        data.title,
        data.body,
        data.dataPayload || {},
      );
      if (result && result.success === false) {
        this.logger.warn(
          `⚠️ [Worker: Notification] Push dispatch reported failure for user ${data.targetUserId}`,
        );
        return false;
      }
      return true;
    } catch (err: any) {
      this.logger.error(
        `❌ [Worker: Notification] Failed to deliver push to ${data.targetUserId}: ${err.message}`,
      );
      return false;
    }
  }
}
