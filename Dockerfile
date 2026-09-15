# Default GHCR image: HTML5 client + Learning Dashboard served by nginx.
# Additional service images live under docker/Dockerfile.*
FROM node:22-bookworm-slim AS html5-builder

WORKDIR /src
RUN apt-get update \
    && apt-get install -y --no-install-recommends git python3 make g++ ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV CI=true \
    NODE_OPTIONS=--max_old_space_size=4096

COPY bigbluebutton-html5/ ./
RUN npm ci --no-progress \
    && NODE_ENV=production DISABLE_ESLINT_PLUGIN=true npm run build \
    && find dist -name '*.js' -exec gzip -k -f -9 '{}' \; \
    && find dist -name '*.css' -exec gzip -k -f -9 '{}' \; \
    && find dist -name '*.wasm' -exec gzip -k -f -9 '{}' \;

FROM node:22-bookworm-slim AS dashboard-builder

WORKDIR /src
ENV CI=true \
    NODE_OPTIONS=--max_old_space_size=4096 \
    DISABLE_ESLINT_PLUGIN=true

COPY bbb-learning-dashboard/ ./
RUN npm ci --no-progress \
    && NODE_ENV=production npm run build

FROM nginx:1.27-alpine

COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=html5-builder /src/dist /usr/share/bigbluebutton/html5-client
COPY --from=dashboard-builder /src/build /www/learning-analytics-dashboard

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz >/dev/null || exit 1
