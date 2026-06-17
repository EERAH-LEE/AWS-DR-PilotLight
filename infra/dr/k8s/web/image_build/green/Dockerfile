# syntax=docker/dockerfile:1

# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM node:22-alpine AS build
WORKDIR /app/web

# 의존성 먼저 복사 (레이어 캐싱 최적화)
COPY package*.json ./
RUN npm ci

# 소스 복사 후 빌드
COPY . .
ARG VITE_API_BASE_URL=/canary
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
RUN npm run build


# ─── Stage 2: Serve ───────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runner

# 기본 nginx 설정 제거 후 커스텀 설정 적용
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 빌드 결과물 복사
COPY --from=build /app/web/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
