#!/bin/bash

# Script para fazer dump do banco local e restaurar no Railway usando URL direta
# Uso: ./dump_to_railway.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Dump Local → Railway PostgreSQL                            ║${NC}"
echo -e "${BLUE}║   Chatwoot/Nokk OMNI                                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# URL de conexão do Railway
RAILWAY_DB_URL="postgresql://postgres:GkPOSSIkVhGxNBDIhPdJkXAVVMeaGlCR@shuttle.proxy.rlwy.net:35620/railway"

# Verificar se pg_dump está instalado
if ! command -v pg_dump &> /dev/null; then
    echo -e "${RED}❌ pg_dump não encontrado!${NC}"
    echo "Instale o PostgreSQL client tools"
    exit 1
fi

# Verificar se psql está instalado
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ psql não encontrado!${NC}"
    echo "Instale o PostgreSQL client tools"
    exit 1
fi

# Carregar variáveis de ambiente do banco local
echo -e "${CYAN}📋 Detectando configurações do banco local...${NC}"

# Tentar carregar do .env ou usar padrões do database.yml
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DATABASE=${POSTGRES_DATABASE:-chatwoot_dev}
POSTGRES_USERNAME=${POSTGRES_USERNAME:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}

# Se não tiver senha, tentar pegar do .env
if [ -z "$POSTGRES_PASSWORD" ] && [ -f .env ]; then
    POSTGRES_PASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" || echo "")
fi

# Se ainda não tiver, tentar pegar do database.yml via Rails
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Tentando detectar senha do database.yml...${NC}"
    # Tentar usar Rails para pegar a configuração
    if command -v bundle &> /dev/null && [ -f Gemfile ]; then
        POSTGRES_PASSWORD=$(bundle exec rails runner "puts ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first.password" 2>/dev/null || echo "")
    fi
fi

echo -e "${GREEN}✅ Configurações do banco local:${NC}"
echo "   Host: ${POSTGRES_HOST}"
echo "   Port: ${POSTGRES_PORT}"
echo "   Database: ${POSTGRES_DATABASE}"
echo "   Username: ${POSTGRES_USERNAME}"
echo ""

echo -e "${GREEN}✅ Configurações do Railway:${NC}"
echo "   URL: postgresql://postgres:***@shuttle.proxy.rlwy.net:35620/railway"
echo ""

# Confirmar antes de continuar
echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá:${NC}"
echo "   1. Fazer dump do banco local: ${POSTGRES_DATABASE}"
echo "   2. Restaurar no Railway (substituindo dados existentes)"
echo ""
read -p "Deseja continuar? (s/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Operação cancelada.${NC}"
    exit 0
fi

# Criar diretório temporário para o dump
DUMP_DIR=$(mktemp -d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="${DUMP_DIR}/chatwoot_dump_${TIMESTAMP}.sql"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Fazendo dump do banco local...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Construir string de conexão para pg_dump
if [ -n "$POSTGRES_PASSWORD" ]; then
    export PGPASSWORD="$POSTGRES_PASSWORD"
fi

# Fazer dump
echo -e "${BLUE}Executando pg_dump...${NC}"
if pg_dump \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USERNAME" \
    -d "$POSTGRES_DATABASE" \
    --no-owner \
    --no-acl \
    --clean \
    --if-exists \
    --verbose \
    -f "$DUMP_FILE" 2>&1; then
    echo -e "${GREEN}✅ Dump criado com sucesso: ${DUMP_FILE}${NC}"
else
    echo -e "${RED}❌ Erro ao fazer dump do banco local${NC}"
    rm -rf "$DUMP_DIR"
    exit 1
fi

# Mostrar tamanho do dump
DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
echo -e "${GREEN}   Tamanho do dump: ${DUMP_SIZE}${NC}"
echo ""

# Verificar conexão com Railway antes de restaurar
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Verificando conexão com Railway...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if psql "$RAILWAY_DB_URL" -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Conexão com Railway estabelecida${NC}"
else
    echo -e "${RED}❌ Erro ao conectar ao Railway${NC}"
    echo -e "${YELLOW}Verifique se a URL está correta e se o banco está acessível${NC}"
    rm -rf "$DUMP_DIR"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠️  ATENÇÃO: Os dados existentes no Railway serão substituídos!${NC}"
read -p "Confirma a restauração? (s/N): " RESTORE_CONFIRM

if [[ ! "$RESTORE_CONFIRM" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Operação cancelada.${NC}"
    echo -e "${GREEN}✅ Dump salvo em: ${DUMP_FILE}${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔄 Restaurando dump no Railway...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}⏳ Isso pode levar alguns minutos dependendo do tamanho do banco...${NC}"
echo ""

# Habilitar extensão pgvector se necessário (antes de restaurar)
echo -e "${BLUE}📌 Habilitando extensão pgvector (se necessário)...${NC}"
psql "$RAILWAY_DB_URL" -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>&1 || {
    echo -e "${YELLOW}⚠️  Não foi possível habilitar pgvector (pode já estar habilitado)${NC}"
}

echo ""

# Restaurar dump
echo -e "${BLUE}📤 Restaurando dump...${NC}"
if psql "$RAILWAY_DB_URL" < "$DUMP_FILE" 2>&1; then
    echo ""
    echo -e "${GREEN}✅ Dump restaurado com sucesso no Railway!${NC}"
    RESTORE_SUCCESS=true
else
    echo ""
    echo -e "${RED}❌ Erro ao restaurar dump${NC}"
    echo -e "${YELLOW}💡 Verifique os erros acima${NC}"
    RESTORE_SUCCESS=false
fi

# Limpar arquivos temporários
echo ""
if [ "$RESTORE_SUCCESS" = true ]; then
    read -p "Deseja manter o arquivo de dump? (S/n): " KEEP_DUMP
    if [[ "$KEEP_DUMP" =~ ^[Nn]$ ]]; then
        rm -rf "$DUMP_DIR"
        echo -e "${GREEN}✅ Arquivos temporários removidos${NC}"
    else
        echo -e "${GREEN}✅ Dump salvo em: ${DUMP_FILE}${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Processo concluído!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "${YELLOW}⚠️  Restauração não foi concluída automaticamente${NC}"
    echo -e "${GREEN}✅ Dump salvo em: ${DUMP_FILE}${NC}"
    echo ""
    echo -e "${BLUE}💡 Você pode tentar restaurar manualmente com:${NC}"
    echo "   psql \"${RAILWAY_DB_URL}\" < ${DUMP_FILE}"
fi

echo ""
echo -e "${BLUE}📝 Próximos passos recomendados:${NC}"
echo ""
echo "   1. Execute as migrations pendentes:"
echo "      export DATABASE_URL=\"${RAILWAY_DB_URL}\""
echo "      bundle exec rails db:migrate"
echo ""
echo "   2. Verifique o status das migrations:"
echo "      export DATABASE_URL=\"${RAILWAY_DB_URL}\""
echo "      bundle exec rails db:migrate:status"
echo ""
echo "   3. Execute os seeds se necessário:"
echo "      export DATABASE_URL=\"${RAILWAY_DB_URL}\""
echo "      bundle exec rails db:seed"
echo ""
