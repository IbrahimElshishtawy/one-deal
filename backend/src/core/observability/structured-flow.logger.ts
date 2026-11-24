import { Logger } from '@nestjs/common';
import {
  getCurrentRequestId,
  isDevelopmentObservabilityEnabled,
  maskEmail,
  maskPhone,
  redactSensitiveData,
} from './request-context';

export type FlowStage =
  | 'REQUEST'
  | 'AUTH'
  | 'VALIDATION'
  | 'DATABASE'
  | 'EMAIL'
  | 'EXTERNAL'
  | 'RESPONSE'
  | 'ERROR';

export type ErrorLayer =
  | 'HTTP'
  | 'VALIDATION'
  | 'AUTH'
  | 'AUTHORIZATION'
  | 'DATABASE'
  | 'EMAIL'
  | 'RATE_LIMIT'
  | 'SERVER';

export type DbCrudCategory = 'CREATE' | 'READ' | 'UPDATE' | 'DELETE';

export class StructuredFlowLogger {
  private static readonly logger = new Logger('DealOneFlow');

  static stage(
    stage: FlowStage,
    message: string,
    meta?: Record<string, unknown>,
    explicitRequestId?: string,
  ): void {
    const requestId = getCurrentRequestId(explicitRequestId);
    const payload: Record<string, unknown> = {
      stage,
      timestamp: new Date().toISOString(),
      requestId,
      message,
      ...(meta ? (redactSensitiveData(meta) as Record<string, unknown>) : {}),
    };
    this.logger.log(`[${stage}] ${message} | ${JSON.stringify(payload)}`);
  }

  /**
   * Logs Database CRUD activity without leaking user records or query payloads.
   */
  static logDatabase(params: {
    operation: DbCrudCategory;
    action: string;
    model: string;
    success: boolean;
    durationMs: number;
    errorCode?: string;
    explicitRequestId?: string;
  }): void {
    const requestId = getCurrentRequestId(params.explicitRequestId);
    const isDev = isDevelopmentObservabilityEnabled();

    // In production, log only failures or slow queries (>500ms) to protect throughput.
    if (!isDev && params.success && params.durationMs < 500) {
      return;
    }

    const summary = `${params.operation} ${params.model}.${params.action} ${params.success ? 'SUCCESS' : 'FAILED'} (${params.durationMs}ms)`;
    const entry = {
      stage: 'DATABASE',
      timestamp: new Date().toISOString(),
      requestId,
      operation: params.operation,
      model: params.model,
      action: params.action,
      status: params.success ? 'SUCCESS' : 'FAILED',
      durationMs: params.durationMs,
      ...(params.errorCode ? { errorCode: params.errorCode } : {}),
    };

    if (params.success) {
      this.logger.log(`[DATABASE] ${summary} | ${JSON.stringify(entry)}`);
    } else {
      this.logger.error(`[DATABASE] ${summary} | ${JSON.stringify(entry)}`);
    }
  }

  /**
   * Logs Email delivery lifecycle with masked recipient and zero secret/token leakage.
   */
  static logEmail(params: {
    event: 'DISPATCHED' | 'SKIPPED' | 'FAILED';
    template: string;
    recipient: string;
    durationMs?: number;
    messageId?: string | null;
    error?: string;
    explicitRequestId?: string;
  }): void {
    const requestId = getCurrentRequestId(params.explicitRequestId);
    const maskedTarget = maskEmail(params.recipient);
    const entry = {
      stage: 'EMAIL',
      timestamp: new Date().toISOString(),
      requestId,
      event: params.event,
      template: params.template,
      recipient: maskedTarget,
      ...(params.durationMs !== undefined ? { durationMs: params.durationMs } : {}),
      ...(params.messageId ? { messageId: params.messageId } : {}),
      ...(params.error ? { error: params.error } : {}),
    };
    const msg = `[EMAIL] ${params.template} -> ${maskedTarget} (${params.event})`;
    if (params.event === 'FAILED') {
      this.logger.error(`${msg} | ${JSON.stringify(entry)}`);
    } else if (params.event === 'SKIPPED') {
      this.logger.warn(`${msg} | ${JSON.stringify(entry)}`);
    } else {
      this.logger.log(`${msg} | ${JSON.stringify(entry)}`);
    }
  }

  /**
   * Development-only OTP terminal logger.
   * Strictly fail-closed: NEVER emits anything outside NODE_ENV === 'development'.
   */
  static logDevOtpGenerated(params: {
    configuredEnv?: string;
    targetPhone?: string;
    targetEmail?: string;
    purpose: string;
    otp: string;
    createdAt: Date;
    expiresAt: Date;
    requestId?: string;
  }): void {
    if (!isDevelopmentObservabilityEnabled(params.configuredEnv)) {
      return;
    }

    const requestId = getCurrentRequestId(params.requestId);
    const maskedTarget = params.targetEmail
      ? maskEmail(params.targetEmail)
      : maskPhone(params.targetPhone);
    const targetLabel = params.targetEmail ? 'Email' : 'Phone';

    const block = [
      '',
      '[AUTH][DEV]',
      'Event: OTP_GENERATED',
      `${targetLabel}: ${maskedTarget}`,
      `Purpose: ${params.purpose}`,
      `OTP: ${params.otp}`,
      `Created At: ${params.createdAt.toISOString()}`,
      `Expires At: ${params.expiresAt.toISOString()}`,
      `Request ID: ${requestId}`,
    ].join('\n');

    this.logger.log(block);
  }

  /**
   * Development-only Email Verification token logger.
   * Strictly fail-closed: NEVER emits anything outside NODE_ENV === 'development'.
   */
  static logDevEmailVerificationGenerated(params: {
    configuredEnv?: string;
    email: string;
    token: string;
    createdAt: Date;
    expiresAt: Date;
    requestId?: string;
  }): void {
    if (!isDevelopmentObservabilityEnabled(params.configuredEnv)) {
      return;
    }

    const requestId = getCurrentRequestId(params.requestId);
    const block = [
      '',
      '[AUTH][DEV]',
      'Event: EMAIL_VERIFICATION_TOKEN_GENERATED',
      `Email: ${maskEmail(params.email)}`,
      'Purpose: EMAIL_VERIFICATION',
      `Verification Token: ${params.token}`,
      `Created At: ${params.createdAt.toISOString()}`,
      `Expires At: ${params.expiresAt.toISOString()}`,
      `Request ID: ${requestId}`,
    ].join('\n');

    this.logger.log(block);
  }

  /**
   * Unified structured error logging with layer classification and dev-only stack traces.
   */
  static logError(params: {
    code: string;
    message: string;
    layer: ErrorLayer;
    statusCode: number;
    requestId?: string;
    path?: string;
    method?: string;
    stack?: string;
  }): void {
    const requestId = getCurrentRequestId(params.requestId);
    const isDev = isDevelopmentObservabilityEnabled();
    const entry = {
      stage: 'ERROR',
      timestamp: new Date().toISOString(),
      requestId,
      layer: params.layer,
      code: params.code,
      statusCode: params.statusCode,
      message: params.message,
      ...(params.method ? { method: params.method } : {}),
      ...(params.path ? { path: params.path } : {}),
    };

    this.logger.error(
      `[ERROR] [${params.layer}] ${params.code} (${params.statusCode}): ${params.message} | ${JSON.stringify(entry)}`,
      isDev ? params.stack : undefined,
    );
  }
}
