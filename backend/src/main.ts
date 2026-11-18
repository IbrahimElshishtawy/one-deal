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
import { parseTrustProxy } from './core/config/env.config';
import {
  buildCorsOptions,
  buildHelmetOptions,
  shouldEnableSwagger,
} from './core/security/http-security.config';
import { HttpExceptionFilter } from './core/filters/http-exception.filter';
import { TransformInterceptor } from './core/interceptors/transform.interceptor';
import { LoggingInterceptor } from './core/interceptors/logging.interceptor';
import { MetricsInterceptor } from './core/metrics/metrics.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  const trustProxy = parseTrustProxy(process.env.TRUST_PROXY);

  const fastifyAdapter = new FastifyAdapter({
    logger: false, // Structured logging handled by LoggingInterceptor
    maxParamLength: 200,
    trustProxy,
  });

  // Preserve raw JSON body string for HMAC webhook signature verification
  fastifyAdapter
    .getInstance()
    .addContentTypeParser(
      'application/json',
      { parseAs: 'string' },
      (req, body, done) => {
        const raw = typeof body === 'string' ? body : body.toString('utf8');
        (req as any).rawBody = raw;
        if (!raw || raw.trim() === '') {
          done(null, {});
          return;
        }
        try {
          done(null, JSON.parse(raw));
        } catch (err: any) {
          err.statusCode = 400;
          done(err, undefined);
        }
      },
    );

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    fastifyAdapter,
  );

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3000);
  const nodeEnv = configService.get<string>('NODE_ENV', 'development');
  const corsOrigin = configService.get<string>('CORS_ORIGIN', '');
  const enableSwagger = configService.get<boolean>('ENABLE_SWAGGER', false);
  const swaggerEnabled = shouldEnableSwagger(nodeEnv, enableSwagger);

  // Security Middleware
  await app.register(helmet, buildHelmetOptions(swaggerEnabled));
  await app.register(cors, buildCorsOptions(corsOrigin, nodeEnv));

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
  if (swaggerEnabled) {
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
  logger.log(
    `🚀 Deal One Backend running on http://0.0.0.0:${port} (env=${nodeEnv}, trustProxy=${JSON.stringify(trustProxy)})`,
  );
}

bootstrap();
