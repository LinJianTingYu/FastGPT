# --------- install dependence -----------
FROM node:18.15-alpine AS mainDeps
WORKDIR /app

ARG name
ARG proxy

RUN [ -z "$proxy" ] || sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk add --no-cache libc6-compat && npm install -g pnpm@8.6.0
# if proxy exists, set proxy
RUN [ -z "$proxy" ] || pnpm config set registry https://registry.npm.taobao.org

# copy packages and one project
COPY pnpm-lock.yaml pnpm-workspace.yaml ./
COPY ./packages ./packages
COPY ./projects/$name/package.json ./projects/$name/package.json

RUN [ -f pnpm-lock.yaml ] || (echo "Lockfile not found." && exit 1)

RUN pnpm i

# --------- install dependence -----------
FROM node:18.15-alpine AS workerDeps
WORKDIR /app

ARG proxy

RUN [ -z "$proxy" ] || sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk add --no-cache libc6-compat && npm install -g pnpm@8.6.0
# if proxy exists, set proxy
RUN [ -z "$proxy" ] || pnpm config set registry https://registry.npm.taobao.org

COPY ./worker /app/worker
RUN cd /app/worker && pnpm i --production --ignore-workspace

# --------- builder -----------
FROM node:18.15-alpine AS builder
WORKDIR /app

ARG name
ARG proxy

# copy common node_modules and one project node_modules
COPY package.json pnpm-workspace.yaml ./
COPY --from=mainDeps /app/node_modules ./node_modules
COPY --from=mainDeps /app/packages ./packages
COPY ./projects/$name ./projects/$name
COPY --from=mainDeps /app/projects/$name/node_modules ./projects/$name/node_modules

RUN [ -z "$proxy" ] || sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk add --no-cache libc6-compat && npm install -g pnpm@8.6.0
RUN pnpm --filter=$name build

# --------- runner -----------
FROM node:18.15-alpine AS runner
WORKDIR /app

ARG name
ARG proxy

# create user and use it
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

RUN [ -z "$proxy" ] || sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk add --no-cache curl ca-certificates \
  && update-ca-certificates

# copy running files
COPY --from=builder /app/projects/$name/public /app/projects/$name/public
COPY --from=builder /app/projects/$name/next.config.js /app/projects/$name/next.config.js
COPY --from=builder --chown=nextjs:nodejs /app/projects/$name/.next/standalone /app/
COPY --from=builder --chown=nextjs:nodejs /app/projects/$name/.next/static /app/projects/$name/.next/static
# copy package.json to version file
COPY --from=builder /app/projects/$name/package.json ./package.json 
# copy woker
COPY --from=workerDeps /app/worker /app/
# copy config
COPY ./projects/$name/data /app/data

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV PORT=3000
ENV MONGODB_URI mongodb://username:password@192.168.1.3:27017/fastgpt?authSource=admin
# PG 数据库连接参数
ENV PG_URL postgresql://username:password@192.168.1.3:5432/postgres
ENV DEFAULT_ROOT_PSW 1234
ENV CHAT_API_KEY sk-ng7e8XwUiAJLvDDc1dB42e1342Ac48Cb9fEc7b326fD7F45f
ENV ONEAPI_URL http://192.168.1.3:3005/v1
ENV TOKEN_KEY dfdasfdas
# 文件阅读时的秘钥
ENV FILE_TOKEN_KEY filetokenkey
# root key, 最高权限
ENV ROOT_KEY fdafasd
ENV DB_MAX_LINK 10
EXPOSE 3000

USER nextjs

ENV serverPath=./projects/$name/server.js

ENTRYPOINT ["sh","-c","node ${serverPath}"]