# Multi-stage Dockerfile for Deal One Backend (Railway Monorepo Root)

# Stage 1: Build & Dependencies
FROM node:20-alpine AS builder

WORKDIR /app

RUN apk add --no-cache openssl

COPY backend/package*.json ./
COPY backend/tsconfig*.json ./
COPY backend/prisma ./prisma/

RUN npm ci
RUN npx prisma generate

COPY backend/src ./src
RUN npm run build

# Preserve generated Prisma client & Prisma CLI/engines, then prune devDependencies
RUN mkdir -p /tmp/prisma-runtime \
    && cp -a node_modules/.prisma /tmp/prisma-runtime/.prisma \
    && cp -a node_modules/prisma /tmp/prisma-runtime/prisma \
    && cp -a node_modules/@prisma /tmp/prisma-runtime/@prisma \
    && npm prune --omit=dev \
    && cp -a /tmp/prisma-runtime/.prisma node_modules/.prisma \
    && cp -a /tmp/prisma-runtime/prisma node_modules/prisma \
    && mkdir -p node_modules/@prisma \
    && cp -a /tmp/prisma-runtime/@prisma/. node_modules/@prisma/ \
    && mkdir -p node_modules/.bin \
    && ln -sf ../prisma/build/index.js node_modules/.bin/prisma \
    && rm -rf /tmp/prisma-runtime

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN apk add --no-cache openssl

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY backend/prisma ./prisma
COPY backend/scripts ./scripts

USER node

EXPOSE 3000

CMD ["sh", "-c", "node scripts/migrate-deploy.js && exec node dist/src/main.js"]
