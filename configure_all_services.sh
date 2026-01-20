#!/bin/bash

# Script para configurar variáveis nos serviços web, worker e uazapi_sse do Railway
# Baseado no arquivo .env local

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Configurando Variáveis nos Serviços Railway                ║${NC}"
echo -e "${BLUE}║   web, worker, uazapi_sse                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar Railway CLI
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI não encontrado!${NC}"
    exit 1
fi

# Verificar .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    exit 1
fi

# Função para configurar variáveis em um serviço
configure_service() {
    local SERVICE_NAME=$1
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔧 Configurando serviço: ${SERVICE_NAME}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Variáveis básicas de ambiente
    echo -e "${BLUE}📝 Configurando variáveis básicas...${NC}"
    
    railway variables --service "$SERVICE_NAME" --set "RAILS_ENV=production" 2>&1 | grep -v "already exists\|Variable set" || true
    railway variables --service "$SERVICE_NAME" --set "NODE_ENV=production" 2>&1 | grep -v "already exists\|Variable set" || true
    railway variables --service "$SERVICE_NAME" --set "INSTALLATION_ENV=railway" 2>&1 | grep -v "already exists\|Variable set" || true
    
    # Logs
    railway variables --service "$SERVICE_NAME" --set "RAILS_LOG_TO_STDOUT=true" 2>&1 | grep -v "already exists\|Variable set" || true
    railway variables --service "$SERVICE_NAME" --set "LOG_LEVEL=info" 2>&1 | grep -v "already exists\|Variable set" || true
    railway variables --service "$SERVICE_NAME" --set "LOG_SIZE=500" 2>&1 | grep -v "already exists\|Variable set" || true
    
    # Performance
    railway variables --service "$SERVICE_NAME" --set "RAILS_MAX_THREADS=5" 2>&1 | grep -v "already exists\|Variable set" || true
    railway variables --service "$SERVICE_NAME" --set "POSTGRES_STATEMENT_TIMEOUT=600s" 2>&1 | grep -v "already exists\|Variable set" || true
    
    # Storage
    railway variables --service "$SERVICE_NAME" --set "ACTIVE_STORAGE_SERVICE=local" 2>&1 | grep -v "already exists\|Variable set" || true
    
    # Account
    railway variables --service "$SERVICE_NAME" --set "ENABLE_ACCOUNT_SIGNUP=false" 2>&1 | grep -v "already exists\|Variable set" || true
    
    # Push relay
    railway variables --service "$SERVICE_NAME" --set "ENABLE_PUSH_RELAY_SERVER=true" 2>&1 | grep -v "already exists\|Variable set" || true
    
    echo -e "${GREEN}✅ Variáveis básicas configuradas${NC}"
    echo ""
    
    # Configurar PostgreSQL usando referências do Railway
    echo -e "${BLUE}🗄️  Configurando PostgreSQL...${NC}"
    
    # Tentar diferentes nomes de serviço PostgreSQL
    for PG_SERVICE in "pgvector" "Postgres" "PostgreSQL" "postgres"; do
        if railway variables --service "$SERVICE_NAME" --set "POSTGRES_HOST=\${{${PG_SERVICE}.PGHOST}}" 2>&1 | grep -q "Variable set\|already exists"; then
            echo -e "${GREEN}✅ PostgreSQL configurado usando serviço: ${PG_SERVICE}${NC}"
            
            railway variables --service "$SERVICE_NAME" --set "POSTGRES_USERNAME=\${{${PG_SERVICE}.PGUSER}}" 2>&1 | grep -v "already exists\|Variable set" || true
            railway variables --service "$SERVICE_NAME" --set "POSTGRES_PASSWORD=\${{${PG_SERVICE}.PGPASSWORD}}" 2>&1 | grep -v "already exists\|Variable set" || true
            railway variables --service "$SERVICE_NAME" --set "POSTGRES_DATABASE=\${{${PG_SERVICE}.PGDATABASE}}" 2>&1 | grep -v "already exists\|Variable set" || true
            railway variables --service "$SERVICE_NAME" --set "DATABASE_URL=\${{${PG_SERVICE}.DATABASE_URL}}" 2>&1 | grep -v "already exists\|Variable set" || true
            break
        fi
    done
    
    echo ""
    
    # Configurar Redis
    echo -e "${BLUE}🔴 Configurando Redis...${NC}"
    
    railway variables --service "$SERVICE_NAME" --set "REDIS_URL=\${{Redis.REDIS_URL}}" 2>&1 | grep -v "already exists\|Variable set" || true
    
    echo -e "${GREEN}✅ Redis configurado${NC}"
    echo ""
    
    # Configurar variáveis específicas do .env
    echo -e "${BLUE}📋 Configurando variáveis do .env...${NC}"
    
    # SMTP (se configurado)
    if grep -q "^SMTP_ADDRESS=" .env && ! grep -q "^SMTP_ADDRESS=$" .env; then
        SMTP_ADDRESS=$(grep "^SMTP_ADDRESS=" .env | cut -d '=' -f2)
        if [ -n "$SMTP_ADDRESS" ]; then
            railway variables --service "$SERVICE_NAME" --set "SMTP_ADDRESS=${SMTP_ADDRESS}" 2>&1 | grep -v "already exists\|Variable set" || true
            
            if grep -q "^SMTP_DOMAIN=" .env; then
                SMTP_DOMAIN=$(grep "^SMTP_DOMAIN=" .env | cut -d '=' -f2)
                [ -n "$SMTP_DOMAIN" ] && railway variables --service "$SERVICE_NAME" --set "SMTP_DOMAIN=${SMTP_DOMAIN}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^SMTP_PORT=" .env; then
                SMTP_PORT=$(grep "^SMTP_PORT=" .env | cut -d '=' -f2)
                [ -n "$SMTP_PORT" ] && railway variables --service "$SERVICE_NAME" --set "SMTP_PORT=${SMTP_PORT}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^SMTP_USERNAME=" .env && ! grep -q "^SMTP_USERNAME=$" .env; then
                SMTP_USERNAME=$(grep "^SMTP_USERNAME=" .env | cut -d '=' -f2)
                [ -n "$SMTP_USERNAME" ] && railway variables --service "$SERVICE_NAME" --set "SMTP_USERNAME=${SMTP_USERNAME}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^SMTP_PASSWORD=" .env && ! grep -q "^SMTP_PASSWORD=$" .env; then
                SMTP_PASSWORD=$(grep "^SMTP_PASSWORD=" .env | cut -d '=' -f2)
                [ -n "$SMTP_PASSWORD" ] && railway variables --service "$SERVICE_NAME" --set "SMTP_PASSWORD=${SMTP_PASSWORD}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^SMTP_AUTHENTICATION=" .env && ! grep -q "^SMTP_AUTHENTICATION=$" .env; then
                SMTP_AUTH=$(grep "^SMTP_AUTHENTICATION=" .env | cut -d '=' -f2)
                [ -n "$SMTP_AUTH" ] && railway variables --service "$SERVICE_NAME" --set "SMTP_AUTHENTICATION=${SMTP_AUTH}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^SMTP_ENABLE_STARTTLS_AUTO=" .env; then
                SMTP_TLS=$(grep "^SMTP_ENABLE_STARTTLS_AUTO=" .env | cut -d '=' -f2)
                [ -n "$SMTP_TLS" ] && railway variables --service "$SERVICE_NAME" --set "SMTP_ENABLE_STARTTLS_AUTO=${SMTP_TLS}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^SMTP_OPENSSL_VERIFY_MODE=" .env; then
                SMTP_VERIFY=$(grep "^SMTP_OPENSSL_VERIFY_MODE=" .env | cut -d '=' -f2)
                [ -n "$SMTP_VERIFY" ] && railway variables --service "$SERVICE_NAME" --set "SMTP_OPENSSL_VERIFY_MODE=${SMTP_VERIFY}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^MAILER_SENDER_EMAIL=" .env; then
                MAILER_SENDER=$(grep "^MAILER_SENDER_EMAIL=" .env | cut -d '=' -f2)
                [ -n "$MAILER_SENDER" ] && railway variables --service "$SERVICE_NAME" --set "MAILER_SENDER_EMAIL=${MAILER_SENDER}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
        fi
    fi
    
    # Storage S3 (se configurado)
    if grep -q "^ACTIVE_STORAGE_SERVICE=s3" .env; then
        if grep -q "^S3_BUCKET_NAME=" .env && ! grep -q "^S3_BUCKET_NAME=$" .env; then
            S3_BUCKET=$(grep "^S3_BUCKET_NAME=" .env | cut -d '=' -f2)
            [ -n "$S3_BUCKET" ] && railway variables --service "$SERVICE_NAME" --set "S3_BUCKET_NAME=${S3_BUCKET}" 2>&1 | grep -v "already exists\|Variable set" || true
            
            if grep -q "^AWS_ACCESS_KEY_ID=" .env && ! grep -q "^AWS_ACCESS_KEY_ID=$" .env; then
                AWS_KEY=$(grep "^AWS_ACCESS_KEY_ID=" .env | cut -d '=' -f2)
                [ -n "$AWS_KEY" ] && railway variables --service "$SERVICE_NAME" --set "AWS_ACCESS_KEY_ID=${AWS_KEY}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^AWS_SECRET_ACCESS_KEY=" .env && ! grep -q "^AWS_SECRET_ACCESS_KEY=$" .env; then
                AWS_SECRET=$(grep "^AWS_SECRET_ACCESS_KEY=" .env | cut -d '=' -f2)
                [ -n "$AWS_SECRET" ] && railway variables --service "$SERVICE_NAME" --set "AWS_SECRET_ACCESS_KEY=${AWS_SECRET}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
            
            if grep -q "^AWS_REGION=" .env && ! grep -q "^AWS_REGION=$" .env; then
                AWS_REGION=$(grep "^AWS_REGION=" .env | cut -d '=' -f2)
                [ -n "$AWS_REGION" ] && railway variables --service "$SERVICE_NAME" --set "AWS_REGION=${AWS_REGION}" 2>&1 | grep -v "already exists\|Variable set" || true
            fi
        fi
    fi
    
    # OpenAI API Key (se configurado)
    if grep -q "^OPENAI_API_KEY=" .env && ! grep -q "^OPENAI_API_KEY=$" .env; then
        OPENAI_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d '=' -f2)
        if [ -n "$OPENAI_KEY" ] && [ "$OPENAI_KEY" != "replace_with_lengthy_secure_hex" ]; then
            railway variables --service "$SERVICE_NAME" --set "OPENAI_API_KEY=${OPENAI_KEY}" 2>&1 | grep -v "already exists\|Variable set" || true
            echo -e "${GREEN}✅ OpenAI API Key configurada${NC}"
        fi
    fi
    
    # ASSET_CDN_HOST (se configurado)
    if grep -q "^ASSET_CDN_HOST=" .env && ! grep -q "^ASSET_CDN_HOST=$" .env; then
        CDN_HOST=$(grep "^ASSET_CDN_HOST=" .env | cut -d '=' -f2)
        [ -n "$CDN_HOST" ] && railway variables --service "$SERVICE_NAME" --set "ASSET_CDN_HOST=${CDN_HOST}" 2>&1 | grep -v "already exists\|Variable set" || true
    fi
    
    echo ""
    echo -e "${GREEN}✅ Serviço ${SERVICE_NAME} configurado!${NC}"
    echo ""
}

# Configurar cada serviço
SERVICES=("web" "worker" "uazapi_sse")

for SERVICE in "${SERVICES[@]}"; do
    configure_service "$SERVICE"
done

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  VARIÁVEIS QUE PRECISAM SER CONFIGURADAS MANUALMENTE:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}1. SECRET_KEY_BASE (OBRIGATÓRIO para todos os serviços):${NC}"
echo "   rails secret"
echo "   railway variables --service web --set \"SECRET_KEY_BASE=<valor_gerado>\""
echo "   railway variables --service worker --set \"SECRET_KEY_BASE=<valor_gerado>\""
echo "   railway variables --service uazapi_sse --set \"SECRET_KEY_BASE=<valor_gerado>\""
echo ""
echo -e "${YELLOW}2. ACTIVE_RECORD_ENCRYPTION_* (OBRIGATÓRIO para MFA):${NC}"
echo "   rails db:encryption:init"
echo "   railway variables --service web --set \"ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...\""
echo "   railway variables --service web --set \"ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...\""
echo "   railway variables --service web --set \"ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...\""
echo "   # Repetir para worker e uazapi_sse"
echo ""
echo -e "${YELLOW}3. FRONTEND_URL (OBRIGATÓRIO apenas para web):${NC}"
echo "   railway domain  # Para ver URL do Railway"
echo "   railway variables --service web --set \"FRONTEND_URL=https://seu-projeto.up.railway.app\""
echo ""
echo -e "${GREEN}✅ Configuração automática concluída!${NC}"
echo ""
