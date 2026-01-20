#!/bin/bash

# Script para configurar variáveis no Railway baseado no arquivo .env local
# Adapta automaticamente valores locais para produção no Railway

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Configurador Railway baseado no .env local                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    exit 1
fi

# Verificar Railway CLI
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI não encontrado!${NC}"
    echo "Instale com: npm i -g @railway/cli"
    exit 1
fi

# Perguntar qual serviço configurar
echo -e "${CYAN}Qual serviço você quer configurar?${NC}"
read -p "Nome do serviço (ex: web, worker): " SERVICE_NAME

if [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}❌ Nome do serviço é obrigatório!${NC}"
    exit 1
fi

# Selecionar serviço
echo -e "${BLUE}Selecionando serviço: ${SERVICE_NAME}...${NC}"
if ! railway service "$SERVICE_NAME" > /dev/null 2>&1; then
    echo -e "${RED}❌ Serviço '${SERVICE_NAME}' não encontrado!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Serviço selecionado${NC}"
echo ""

# Função para configurar variável (ignora se já existe)
set_var() {
    local VAR_NAME=$1
    local VAR_VALUE=$2
    local SKIP_IF_EXISTS=${3:-false}
    
    if [ "$SKIP_IF_EXISTS" = "true" ]; then
        railway variables set "${VAR_NAME}=${VAR_VALUE}" 2>&1 | grep -v "already exists" || true
    else
        railway variables set "${VAR_NAME}=${VAR_VALUE}" 2>&1 || true
    fi
}

echo -e "${BLUE}📝 Configurando variáveis de ambiente...${NC}"

# Ambiente (sempre produção no Railway)
set_var "RAILS_ENV" "production" true
set_var "NODE_ENV" "production" true
set_var "INSTALLATION_ENV" "railway" true

# Logs
set_var "RAILS_LOG_TO_STDOUT" "true" true
set_var "LOG_LEVEL" "info" true
set_var "LOG_SIZE" "500" true

# Performance
set_var "RAILS_MAX_THREADS" "5" true
set_var "POSTGRES_STATEMENT_TIMEOUT" "600s" true

# Storage (do .env)
if grep -q "^ACTIVE_STORAGE_SERVICE=" .env; then
    STORAGE=$(grep "^ACTIVE_STORAGE_SERVICE=" .env | cut -d '=' -f2)
    if [ -n "$STORAGE" ]; then
        set_var "ACTIVE_STORAGE_SERVICE" "$STORAGE" true
    fi
fi

# Account signup
if grep -q "^ENABLE_ACCOUNT_SIGNUP=" .env; then
    SIGNUP=$(grep "^ENABLE_ACCOUNT_SIGNUP=" .env | cut -d '=' -f2)
    if [ -n "$SIGNUP" ]; then
        set_var "ENABLE_ACCOUNT_SIGNUP" "$SIGNUP" true
    fi
fi

# Push relay
if grep -q "^ENABLE_PUSH_RELAY_SERVER=" .env; then
    PUSH_RELAY=$(grep "^ENABLE_PUSH_RELAY_SERVER=" .env | cut -d '=' -f2)
    if [ -n "$PUSH_RELAY" ]; then
        set_var "ENABLE_PUSH_RELAY_SERVER" "$PUSH_RELAY" true
    fi
fi

# Force SSL (se configurado)
if grep -q "^FORCE_SSL=" .env; then
    FORCE_SSL=$(grep "^FORCE_SSL=" .env | cut -d '=' -f2)
    if [ -n "$FORCE_SSL" ]; then
        set_var "FORCE_SSL" "$FORCE_SSL" true
    fi
fi

echo -e "${GREEN}✅ Variáveis básicas configuradas${NC}"
echo ""

# Configurar PostgreSQL usando referências do Railway
echo -e "${BLUE}🗄️  Configurando PostgreSQL (usando referências do Railway)...${NC}"

# Tentar diferentes nomes de serviço PostgreSQL
for PG_SERVICE in "pgvector" "Postgres" "PostgreSQL" "postgres"; do
    if railway variables set "POSTGRES_HOST=\${{${PG_SERVICE}.PGHOST}}" 2>&1 | grep -q "Variable set\|already exists"; then
        echo -e "${GREEN}✅ PostgreSQL configurado usando serviço: ${PG_SERVICE}${NC}"
        
        set_var "POSTGRES_USERNAME" "\${{${PG_SERVICE}.PGUSER}}" true
        set_var "POSTGRES_PASSWORD" "\${{${PG_SERVICE}.PGPASSWORD}}" true
        set_var "POSTGRES_DATABASE" "\${{${PG_SERVICE}.PGDATABASE}}" true
        set_var "DATABASE_URL" "\${{${PG_SERVICE}.DATABASE_URL}}" true
        break
    fi
done

echo ""

# Configurar Redis usando referências do Railway
echo -e "${BLUE}🔴 Configurando Redis (usando referências do Railway)...${NC}"

if railway variables set "REDIS_URL=\${{Redis.REDIS_URL}}" 2>&1 | grep -q "Variable set\|already exists"; then
    echo -e "${GREEN}✅ Redis configurado${NC}"
else
    echo -e "${YELLOW}⚠️  Redis não encontrado. Configure manualmente depois.${NC}"
fi

echo ""

# Configurar variáveis do .env que são válidas para produção
echo -e "${BLUE}📋 Configurando variáveis específicas do .env...${NC}"

# SMTP (se configurado)
if grep -q "^SMTP_ADDRESS=" .env && ! grep -q "^SMTP_ADDRESS=$" .env; then
    SMTP_ADDRESS=$(grep "^SMTP_ADDRESS=" .env | cut -d '=' -f2)
    if [ -n "$SMTP_ADDRESS" ]; then
        set_var "SMTP_ADDRESS" "$SMTP_ADDRESS" true
        
        # Outras variáveis SMTP
        if grep -q "^SMTP_DOMAIN=" .env; then
            SMTP_DOMAIN=$(grep "^SMTP_DOMAIN=" .env | cut -d '=' -f2)
            [ -n "$SMTP_DOMAIN" ] && set_var "SMTP_DOMAIN" "$SMTP_DOMAIN" true
        fi
        
        if grep -q "^SMTP_PORT=" .env; then
            SMTP_PORT=$(grep "^SMTP_PORT=" .env | cut -d '=' -f2)
            [ -n "$SMTP_PORT" ] && set_var "SMTP_PORT" "$SMTP_PORT" true
        fi
        
        if grep -q "^SMTP_USERNAME=" .env && ! grep -q "^SMTP_USERNAME=$" .env; then
            SMTP_USERNAME=$(grep "^SMTP_USERNAME=" .env | cut -d '=' -f2)
            [ -n "$SMTP_USERNAME" ] && set_var "SMTP_USERNAME" "$SMTP_USERNAME" true
        fi
        
        if grep -q "^SMTP_PASSWORD=" .env && ! grep -q "^SMTP_PASSWORD=$" .env; then
            SMTP_PASSWORD=$(grep "^SMTP_PASSWORD=" .env | cut -d '=' -f2)
            [ -n "$SMTP_PASSWORD" ] && set_var "SMTP_PASSWORD" "$SMTP_PASSWORD" true
        fi
        
        if grep -q "^SMTP_AUTHENTICATION=" .env && ! grep -q "^SMTP_AUTHENTICATION=$" .env; then
            SMTP_AUTH=$(grep "^SMTP_AUTHENTICATION=" .env | cut -d '=' -f2)
            [ -n "$SMTP_AUTH" ] && set_var "SMTP_AUTHENTICATION" "$SMTP_AUTH" true
        fi
        
        if grep -q "^SMTP_ENABLE_STARTTLS_AUTO=" .env; then
            SMTP_TLS=$(grep "^SMTP_ENABLE_STARTTLS_AUTO=" .env | cut -d '=' -f2)
            [ -n "$SMTP_TLS" ] && set_var "SMTP_ENABLE_STARTTLS_AUTO" "$SMTP_TLS" true
        fi
        
        if grep -q "^SMTP_OPENSSL_VERIFY_MODE=" .env; then
            SMTP_VERIFY=$(grep "^SMTP_OPENSSL_VERIFY_MODE=" .env | cut -d '=' -f2)
            [ -n "$SMTP_VERIFY" ] && set_var "SMTP_OPENSSL_VERIFY_MODE" "$SMTP_VERIFY" true
        fi
        
        if grep -q "^MAILER_SENDER_EMAIL=" .env; then
            MAILER_SENDER=$(grep "^MAILER_SENDER_EMAIL=" .env | cut -d '=' -f2)
            [ -n "$MAILER_SENDER" ] && set_var "MAILER_SENDER_EMAIL" "$MAILER_SENDER" true
        fi
        
        echo -e "${GREEN}✅ SMTP configurado${NC}"
    fi
fi

# Storage S3 (se configurado)
if grep -q "^ACTIVE_STORAGE_SERVICE=s3" .env; then
    if grep -q "^S3_BUCKET_NAME=" .env && ! grep -q "^S3_BUCKET_NAME=$" .env; then
        S3_BUCKET=$(grep "^S3_BUCKET_NAME=" .env | cut -d '=' -f2)
        [ -n "$S3_BUCKET" ] && set_var "S3_BUCKET_NAME" "$S3_BUCKET" true
        
        if grep -q "^AWS_ACCESS_KEY_ID=" .env && ! grep -q "^AWS_ACCESS_KEY_ID=$" .env; then
            AWS_KEY=$(grep "^AWS_ACCESS_KEY_ID=" .env | cut -d '=' -f2)
            [ -n "$AWS_KEY" ] && set_var "AWS_ACCESS_KEY_ID" "$AWS_KEY" true
        fi
        
        if grep -q "^AWS_SECRET_ACCESS_KEY=" .env && ! grep -q "^AWS_SECRET_ACCESS_KEY=$" .env; then
            AWS_SECRET=$(grep "^AWS_SECRET_ACCESS_KEY=" .env | cut -d '=' -f2)
            [ -n "$AWS_SECRET" ] && set_var "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET" true
        fi
        
        if grep -q "^AWS_REGION=" .env && ! grep -q "^AWS_REGION=$" .env; then
            AWS_REGION=$(grep "^AWS_REGION=" .env | cut -d '=' -f2)
            [ -n "$AWS_REGION" ] && set_var "AWS_REGION" "$AWS_REGION" true
        fi
        
        echo -e "${GREEN}✅ S3 configurado${NC}"
    fi
fi

# OpenAI API Key (se configurado)
if grep -q "^OPENAI_API_KEY=" .env && ! grep -q "^OPENAI_API_KEY=$" .env; then
    OPENAI_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d '=' -f2)
    if [ -n "$OPENAI_KEY" ] && [ "$OPENAI_KEY" != "replace_with_lengthy_secure_hex" ]; then
        set_var "OPENAI_API_KEY" "$OPENAI_KEY" true
        echo -e "${GREEN}✅ OpenAI API Key configurada${NC}"
    fi
fi

# Outras variáveis opcionais (se configuradas)
if grep -q "^ASSET_CDN_HOST=" .env && ! grep -q "^ASSET_CDN_HOST=$" .env; then
    CDN_HOST=$(grep "^ASSET_CDN_HOST=" .env | cut -d '=' -f2)
    [ -n "$CDN_HOST" ] && set_var "ASSET_CDN_HOST" "$CDN_HOST" true
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  VARIÁVEIS QUE PRECISAM SER CONFIGURADAS MANUALMENTE:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar SECRET_KEY_BASE
if grep -q "^SECRET_KEY_BASE=" .env; then
    SECRET_KEY=$(grep "^SECRET_KEY_BASE=" .env | cut -d '=' -f2)
    if [ "$SECRET_KEY" = "replace_with_lengthy_secure_hex" ] || [ -z "$SECRET_KEY" ]; then
        echo -e "${RED}1. SECRET_KEY_BASE (OBRIGATÓRIO) - Precisa gerar:${NC}"
        echo "   rails secret"
        echo "   railway variables set SECRET_KEY_BASE=<valor_gerado>"
        echo ""
    else
        echo -e "${GREEN}✓ SECRET_KEY_BASE já configurado no .env${NC}"
        echo "   (mas você precisa configurar manualmente no Railway)"
        echo ""
    fi
else
    echo -e "${RED}1. SECRET_KEY_BASE (OBRIGATÓRIO) - Precisa gerar:${NC}"
    echo "   rails secret"
    echo "   railway variables set SECRET_KEY_BASE=<valor_gerado>"
    echo ""
fi

# Verificar Encryption Keys
if grep -q "^ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=" .env && ! grep -q "^# ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=" .env; then
    ENC_KEY=$(grep "^ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=" .env | cut -d '=' -f2)
    if [ -z "$ENC_KEY" ]; then
        echo -e "${YELLOW}2. ACTIVE_RECORD_ENCRYPTION_* (OBRIGATÓRIO para MFA) - Precisa gerar:${NC}"
        echo "   rails db:encryption:init"
        echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=..."
        echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=..."
        echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=..."
        echo ""
    fi
else
    echo -e "${YELLOW}2. ACTIVE_RECORD_ENCRYPTION_* (OBRIGATÓRIO para MFA) - Precisa gerar:${NC}"
    echo "   rails db:encryption:init"
    echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=..."
    echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=..."
    echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=..."
    echo ""
fi

# FRONTEND_URL
echo -e "${YELLOW}3. FRONTEND_URL (OBRIGATÓRIO) - Precisa configurar:${NC}"
echo "   railway domain  # Para ver URL do Railway"
echo "   railway variables set FRONTEND_URL=https://seu-projeto.up.railway.app"
echo "   # Ou se usar domínio customizado:"
echo "   railway variables set FRONTEND_URL=https://chatwoot.seudominio.com"
echo ""

echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
