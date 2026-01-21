#!/bin/bash

# Script para configurar variáveis de ambiente nos serviços do Railway
# Uso: ./configure_railway_vars.sh [servico]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Configurador de Variáveis Railway - Chatwoot/Nokk OMNI   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se railway CLI está instalado
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI não encontrado!${NC}"
    echo "Instale com: npm i -g @railway/cli"
    exit 1
fi

# Listar serviços disponíveis
echo -e "${YELLOW}📋 Serviços disponíveis no Railway:${NC}"
railway status 2>&1 | grep -E "Service:|Project:" || true
echo ""

# Função para configurar variáveis em um serviço específico
configure_service() {
    local SERVICE=$1
    
    echo -e "${GREEN}🔧 Configurando variáveis para serviço: ${SERVICE}${NC}"
    echo ""
    
    # Mudar para o serviço
    railway service "$SERVICE" 2>&1 || {
        echo -e "${RED}❌ Erro ao selecionar serviço ${SERVICE}${NC}"
        return 1
    }
    
    # Variáveis básicas de ambiente
    echo -e "${BLUE}📝 Configurando variáveis básicas...${NC}"
    
    railway variables set RAILS_ENV=production
    railway variables set NODE_ENV=production
    railway variables set INSTALLATION_ENV=railway
    railway variables set RAILS_LOG_TO_STDOUT=true
    railway variables set LOG_LEVEL=info
    railway variables set LOG_SIZE=500
    railway variables set RAILS_MAX_THREADS=5
    railway variables set POSTGRES_STATEMENT_TIMEOUT=600s
    
    # Storage
    railway variables set ACTIVE_STORAGE_SERVICE=local
    
    # Account signup
    railway variables set ENABLE_ACCOUNT_SIGNUP=false
    
    # Push relay
    railway variables set ENABLE_PUSH_RELAY_SERVER=true
    
    echo -e "${GREEN}✅ Variáveis básicas configuradas!${NC}"
    echo ""
    
    # Variáveis de banco de dados (usando referências do Railway)
    echo -e "${BLUE}🗄️  Configurando variáveis de banco de dados...${NC}"
    
    # Tentar usar referências do Railway para PostgreSQL
    # Nota: Ajuste o nome do serviço PostgreSQL conforme necessário
    railway variables set POSTGRES_HOST='${{pgvector.PGHOST}}' 2>&1 || \
    railway variables set POSTGRES_HOST='${{Postgres.PGHOST}}' 2>&1 || \
    railway variables set POSTGRES_HOST='${{PostgreSQL.PGHOST}}' 2>&1 || true
    
    railway variables set POSTGRES_USERNAME='${{pgvector.PGUSER}}' 2>&1 || \
    railway variables set POSTGRES_USERNAME='${{Postgres.PGUSER}}' 2>&1 || \
    railway variables set POSTGRES_USERNAME='${{PostgreSQL.PGUSER}}' 2>&1 || true
    
    railway variables set POSTGRES_PASSWORD='${{pgvector.PGPASSWORD}}' 2>&1 || \
    railway variables set POSTGRES_PASSWORD='${{Postgres.PGPASSWORD}}' 2>&1 || \
    railway variables set POSTGRES_PASSWORD='${{PostgreSQL.PGPASSWORD}}' 2>&1 || true
    
    railway variables set POSTGRES_DATABASE='${{pgvector.PGDATABASE}}' 2>&1 || \
    railway variables set POSTGRES_DATABASE='${{Postgres.PGDATABASE}}' 2>&1 || \
    railway variables set POSTGRES_DATABASE='${{PostgreSQL.PGDATABASE}}' 2>&1 || true
    
    # DATABASE_URL
    railway variables set DATABASE_URL='${{pgvector.DATABASE_URL}}' 2>&1 || \
    railway variables set DATABASE_URL='${{Postgres.DATABASE_URL}}' 2>&1 || \
    railway variables set DATABASE_URL='${{PostgreSQL.DATABASE_URL}}' 2>&1 || true
    
    echo -e "${GREEN}✅ Variáveis de banco configuradas!${NC}"
    echo ""
    
    # Variáveis de Redis
    echo -e "${BLUE}🔴 Configurando variáveis de Redis...${NC}"
    
    railway variables set REDIS_URL='${{Redis.REDIS_URL}}' 2>&1 || true
    
    echo -e "${GREEN}✅ Variáveis de Redis configuradas!${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠️  ATENÇÃO: Configure manualmente as seguintes variáveis:${NC}"
    echo ""
    echo -e "${YELLOW}1. SECRET_KEY_BASE (obrigatório):${NC}"
    echo "   railway variables set SECRET_KEY_BASE=\$(rails secret)"
    echo ""
    echo -e "${YELLOW}2. ACTIVE_RECORD_ENCRYPTION_* (obrigatório para MFA):${NC}"
    echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=..."
    echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=..."
    echo "   railway variables set ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=..."
    echo ""
    echo -e "${YELLOW}3. FRONTEND_URL (obrigatório):${NC}"
    echo "   railway variables set FRONTEND_URL=https://seu-projeto.up.railway.app"
    echo ""
    echo -e "${YELLOW}4. SMTP (opcional, se usar email):${NC}"
    echo "   railway variables set SMTP_ADDRESS=smtp.gmail.com"
    echo "   railway variables set SMTP_PORT=587"
    echo "   railway variables set SMTP_USERNAME=seu_email@gmail.com"
    echo "   railway variables set SMTP_PASSWORD=sua_senha_app"
    echo ""
}

# Se serviço foi passado como argumento
if [ -n "$1" ]; then
    configure_service "$1"
else
    echo -e "${YELLOW}ℹ️  Uso: ./configure_railway_vars.sh [nome-do-servico]${NC}"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  ./configure_railway_vars.sh web        # Para serviço web Rails"
    echo "  ./configure_railway_vars.sh worker      # Para serviço Sidekiq worker"
    echo ""
    echo -e "${BLUE}Para listar serviços disponíveis:${NC}"
    echo "  railway status"
    echo ""
    echo -e "${BLUE}Para configurar manualmente:${NC}"
    echo "  railway service [nome-servico]"
    echo "  railway variables set VAR=value"
fi
