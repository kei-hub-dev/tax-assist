FROM ruby:3.3-slim

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 \
    GROVER_NO_SANDBOX=1 \
    NODE_PATH=/usr/local/lib/node_modules

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
    fonts-noto-cjk \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g puppeteer --no-audit --no-fund
RUN gem update --system && gem install bundler -v 2.3.27

WORKDIR /workspace

COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform x86_64-linux || true
RUN bundle config set force_ruby_platform true
RUN bundle install

COPY . .

RUN test -f package.json || npm init -y
RUN npm install puppeteer --no-audit --no-fund

EXPOSE 3000
CMD ["bash","-lc","exec bin/rails s -b 0.0.0.0 -p ${PORT:-3000}"]
