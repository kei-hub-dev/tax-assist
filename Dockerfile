FROM ruby:3.3-slim

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    libpq-dev \
    libyaml-dev \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

RUN gem update --system && gem install bundler -v 2.3.27

WORKDIR /workspace

COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform x86_64-linux || true
RUN bundle config set force_ruby_platform true
RUN bundle install

COPY . .

EXPOSE 3000

 CMD ["bash","-lc","exec bin/rails s -b 0.0.0.0 -p ${PORT:-3000}"]
# CMD ["bash","-lc","bin/rails db:prepare && bin/rails s -b 0.0.0.0 -p ${PORT:-3000}"]
