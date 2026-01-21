# =========================
# NODE BASE (somente para copiar binários)
# =========================
FROM node:24-slim AS node

# =========================
# PRE-BUILDER
# =========================
FROM ruby:3.4.4-slim AS pre-builder

# ← ARGs para usar no BUILD
ARG FRONTEND_URL
ARG ACTION_CABLE_URL
ARG PNPM_VERSION="10.2.0"
ARG BUNDLER_VERSION="2.5.11"

ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLE_PATH="/gems"
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV VITE_RUBY_SKIP_COMPATIBILITY_CHECK=true
ENV DOCKER_BUILD=true

# Dependências de build
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  postgresql-client \
  git \
  curl \
  ca-certificates \
  libvips42 \
  libvips-dev \
  libyaml-dev \
  && rm -rf /var/lib/apt/lists/* \
  && gem install bundler -v ${BUNDLER_VERSION}

WORKDIR /app

# Node + npm
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# pnpm
RUN npm install -g pnpm@${PNPM_VERSION}
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="${PNPM_HOME}:${PATH}"

# Gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'development test' \
 && bundle install -j 4 -r 3

# JS deps
COPY package.json pnpm-lock.yaml ./
COPY config ./config
RUN pnpm install --frozen-lockfile

# Código
COPY . /app
RUN mkdir -p /app/log

# =========================
# BUILD DO SDK (ÚNICO build JS manual permitido)
# =========================
RUN echo "Building Chatwoot SDK..." \
 && BUILD_MODE=library pnpm run build:sdk

# =========================
# ASSETS PRECOMPILE (VITE + RAILS)
# =========================
RUN SECRET_KEY_BASE=precompile_placeholder \
    RAILS_LOG_TO_STDOUT=true \
    DATABASE_URL=postgresql://postgres:postgres@localhost/chatwoot_production \
    FRONTEND_URL=${FRONTEND_URL:-http://localhost:3000} \
    ACTION_CABLE_URL=${ACTION_CABLE_URL:-ws://localhost:3000/cable} \
    VITE_RUBY_SKIP_COMPATIBILITY_CHECK=true \
    bundle exec rake assets:precompile \
 && rm -rf spec tmp/cache

# git sha
RUN git rev-parse HEAD > /app/.git_sha 2>/dev/null || echo "unknown" > /app/.git_sha

# limpeza
RUN rm -rf /gems/ruby/3.4.0/cache/*.gem \
 && find /gems/ruby/3.4.0/gems \( -name "*.c" -o -name "*.o" \) -delete \
 && rm -rf .git .gitignore

# =========================
# RUNTIME FINAL
# =========================
FROM ruby:3.4.4-slim

# ← ADICIONAR ARGs AQUI TAMBÉM
ARG FRONTEND_URL
ARG ACTION_CABLE_URL
ARG BUNDLER_VERSION="2.5.11"

ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLE_PATH="/gems"
ENV RAILS_SERVE_STATIC_FILES=true
ENV EXECJS_RUNTIME=Disabled

# ← PROPAGAR PARA ENV (para runtime)
ENV FRONTEND_URL=${FRONTEND_URL}
ENV ACTION_CABLE_URL=${ACTION_CABLE_URL}

RUN apt-get update && apt-get install -y --no-install-recommends \
  postgresql-client \
  libvips42 \
  imagemagick \
  git \
  ca-certificates \
  libyaml-0-2 \
  && rm -rf /var/lib/apt/lists/* \
  && gem install bundler -v ${BUNDLER_VERSION}

# Node (runtime para ExecJS / mini_racer / etc)
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

# App
COPY --from=pre-builder /gems /gems
COPY --from=pre-builder /app /app

WORKDIR /app

EXPOSE 3000
