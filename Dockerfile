FROM ruby:3.4.10-slim-trixie

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 \
    GROVER_NO_SANDBOX=1 \
    NODE_PATH=/usr/local/lib/node_modules

ARG BUILD_ASSETS=0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    libpq-dev \
    libyaml-dev \
    pkg-config \
    nodejs \
    npm \
    chromium \
    chromium-driver \
    fonts-noto-cjk \
  && rm -rf /var/lib/apt/lists/*

RUN gem update --system && gem install bundler -v 2.7.2

WORKDIR /workspace

COPY Gemfile Gemfile.lock ./
RUN bundle install

# node_modules は /workspace の外(= /node_modules)に置く。
# compose.yaml のバインドマウント (.:/workspace) が /workspace/node_modules を
# 覆い隠してしまい、grover が puppeteer を解決できなくなるため。
# Node は /workspace/node_modules の次に /node_modules を探索する。
COPY package.json package-lock.json /
RUN cd / && npm ci --omit=dev --no-audit --no-fund

COPY . .

RUN bash -lc 'set -euo pipefail; \
  if [ "${BUILD_ASSETS}" = "1" ]; then \
    export RAILS_ENV=production NODE_ENV=production SECRET_KEY_BASE=dummy DISABLE_DATABASE_ENVIRONMENT_CHECK=1; \
    export APP_HOST="${BUILD_APP_HOST:-tax-assist.fly.dev}"; \
    export SMTP_ADDRESS="${BUILD_SMTP_ADDRESS:-localhost}"; \
    export SMTP_PORT="${BUILD_SMTP_PORT:-587}"; \
    export SMTP_USERNAME="${BUILD_SMTP_USERNAME:-dummy}"; \
    export SMTP_USER_NAME="${SMTP_USERNAME}"; \
    export SMTP_PASSWORD="${BUILD_SMTP_PASSWORD:-dummy}"; \
    export SMTP_DOMAIN="${BUILD_SMTP_DOMAIN:-example.com}"; \
    export SMTP_AUTHENTICATION="${BUILD_SMTP_AUTHENTICATION:-plain}"; \
    export SMTP_ENABLE_STARTTLS_AUTO="${BUILD_SMTP_ENABLE_STARTTLS_AUTO:-true}"; \
    bundle exec rails assets:clobber assets:precompile; \
  else \
    echo "skip assets:precompile (BUILD_ASSETS=${BUILD_ASSETS})"; \
  fi'


EXPOSE 3000
CMD ["bash","-lc","rm -f tmp/pids/server.pid && exec bin/rails s -b 0.0.0.0 -p ${PORT:-3000}"]
