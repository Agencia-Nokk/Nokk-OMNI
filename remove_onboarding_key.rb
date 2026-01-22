#!/usr/bin/env ruby
# Script para remover a chave CHATWOOT_INSTALLATION_ONBOARDING do Redis
# Uso: bundle exec rails runner remove_onboarding_key.rb

require_relative 'config/environment'

if User.exists?
  Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  puts "✅ Chave CHATWOOT_INSTALLATION_ONBOARDING removida do Redis (usuários existem no banco)"
else
  puts "⚠️  Nenhum usuário encontrado no banco. Mantendo a chave para onboarding."
end
