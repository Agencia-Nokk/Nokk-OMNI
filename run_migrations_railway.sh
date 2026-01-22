#!/bin/bash

# Script para executar migrations no banco de produção do Railway
# Uso: ./run_migrations_railway.sh

set -e

echo "🚀 Executando migrations no banco de produção do Railway..."
echo ""

# URL de conexão do Railway
export DATABASE_URL="postgresql://postgres:GkPOSSIkVhGxNBDIhPdJkXAVVMeaGlCR@shuttle.proxy.rlwy.net:35620/railway"

# Verificar conexão
echo "📡 Verificando conexão com o banco..."
bundle exec rails db:migrate:status > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Erro ao conectar ao banco de dados"
    exit 1
fi

echo "✅ Conexão estabelecida"
echo ""

# Mostrar status antes
echo "📊 Status das migrations ANTES:"
bundle exec rails db:migrate:status 2>&1 | grep -E "(down|up.*NO FILE)" || true
echo ""

# Executar migrations
echo "🔄 Executando migrations pendentes..."
bundle exec rails db:migrate

echo ""
echo "✅ Migrations executadas com sucesso!"
echo ""

# Mostrar status depois
echo "📊 Status das migrations DEPOIS:"
bundle exec rails db:migrate:status 2>&1 | tail -10

echo ""
echo "✨ Processo concluído!"
