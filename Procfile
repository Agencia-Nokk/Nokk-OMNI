release: eval "$(rbenv init -)" && POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && echo $SOURCE_VERSION > .git_sha
web: eval "$(rbenv init -)" && bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV
worker: eval "$(rbenv init -)" && bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
uazapi_sse: eval "$(rbenv init -)" && bundle exec rake uazapi:sse_daemon
