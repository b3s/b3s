#### Rails image ##############################################################

ARG RUBY_VERSION='4.0.0'

FROM ruby:$RUBY_VERSION-bookworm AS runtime

ARG RUBYGEMS_VERSION='4.0.3'
ARG BUNDLER_VERSION='4.0.3'
ARG NVM_VERSION='0.40.3'
ARG NODE_VERSION='24.1.0'
ARG PG_MAJOR='15'

ENV DEBIAN_FRONTEND=noninteractive

# Add PostgreSQL to sources list
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
        && echo 'deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

# Install dependencies
RUN apt-get update -qq && apt-get -yq upgrade && \
    apt-get install -yq --no-install-recommends \
    libvips libpq-dev postgresql-client-$PG_MAJOR nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Install nvm and node
RUN mkdir /usr/local/nvm
ENV NVM_DIR=/usr/local/nvm
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default

# Install pnpm
RUN npm install --global pnpm

# Configure bundler
ENV LANG=C.UTF-8 \
        BUNDLE_JOBS=8 \
        BUNDLE_RETRY=3

# Install required Bundler version
RUN gem update --system $RUBYGEMS_VERSION && \
        rm /usr/local/lib/ruby/gems/*/specifications/default/bundler-*.gemspec && \
        gem uninstall bundler && \
        gem install bundler -v $BUNDLER_VERSION

# Default environment variables
ENV LANG=C.UTF-8 \
        RAILS_ENV=production \
        RAILS_LOG_TO_STDOUT=1 \
        RAILS_SERVE_STATIC_FILES=1

# Create a directory for the app code
RUN mkdir -p /app
WORKDIR /app

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Create nginx cache directory
RUN mkdir -p /var/cache/nginx/images

# Start server via nginx + Puma, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/docker-start"]


#### Development ##############################################################

FROM runtime AS development

RUN bundle config --local without ''


#### Gems #####################################################################

FROM runtime AS gems

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config --local without 'development test' && \
    bundle install


#### App w/ dependencies ######################################################

FROM runtime AS app

# Install pnpm dependencies
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# Copy gems
COPY --from=gems /usr/local/bundle/ /usr/local/bundle/

# Install the app
COPY . ./


#### Precompile assets ########################################################

FROM app AS assets

RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile


#### Production ###############################################################

FROM app AS prod

ENV LANG=C.UTF-8 \
        RAILS_ENV=production \
        RAILS_LOG_TO_STDOUT=1 \
        RAILS_SERVE_STATIC_FILES=1

COPY --from=assets /app/app/assets/builds ./app/assets/builds
COPY --from=assets /app/public/assets ./public/assets

# Install nginx config template
COPY config/nginx.conf.template /etc/nginx/nginx.conf.template
