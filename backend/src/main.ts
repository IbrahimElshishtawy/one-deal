import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from '@fastify/helmet';
import cors from '@fastify/cors';

import { AppModule } from './app.module';
import { HttpExceptionFilter } from './core/filters/http-exception.filter';
import { TransformInterceptor } from './core/interceptors/transform.interceptor';
import { LoggingInterceptor } from './core/interceptors/logging.interceptor';
import { MetricsInterceptor } from './core/metrics/metrics.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({
      logger: false, // Structured logging handled by LoggingInterceptor / Pino
      maxParamLength: 200,
    }),
  );

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3000);
  const corsOrigin = configService.get<string>('CORS_ORIGIN', '*');

  // Security Middleware
  await app.register(helmet, {
    contentSecurityPolicy: false, // Allow Swagger UI
  });

  await app.register(cors, {
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    credentials: true,
  });

  // Global Validation & Exception Pipelines
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(
    app.get(MetricsInterceptor),
    new LoggingInterceptor(),
    new TransformInterceptor(),
  );

  // Global API Prefix with health & metrics endpoint exclusions
  app.setGlobalPrefix('api/v1', {
    exclude: [
      'health/live',
      'health/ready',
      'health/liveness',
      'health/readiness',
      'metrics',
    ],
  });

  // Swagger Documentation Setup (disabled in production by default)
  const nodeEnv = configService.get<string>('NODE_ENV', 'development');
  const enableSwagger = configService.get<boolean>('ENABLE_SWAGGER', false);
  if (nodeEnv !== 'production' || enableSwagger) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Deal One API (صفقة ون)')
      .setDescription(
        'Production Modular Monolith classifieds marketplace backend API for Egypt',
      )
      .setVersion('1.0.0')
      .addBearerAuth(
        { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
        'BearerAuth',
      )
      .build();

    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, document);
    logger.log(
      `📚 OpenAPI Documentation available at http://0.0.0.0:${port}/api/docs`,
    );
  } else {
    logger.log('🔒 Swagger UI disabled in production environment');
  }

  // Enable Graceful Shutdown Hooks
  app.enableShutdownHooks();

  await app.listen(port, '0.0.0.0');
  logger.log(`🚀 Deal One Backend running on http://0.0.0.0:${port}`);
}

bootstrap();
