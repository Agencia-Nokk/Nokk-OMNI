#!/bin/bash

# Script interativo para configurar variáveis nos serviços do Railway
# Detecta automaticamente os serviços e configura as variáveis necessárias

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Configurador Automático de Variáveis Railway              ║${NC}"
echo -e "${BLUE}║   Chatwoot/Nokk OMNI                                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar Railway CLI
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI não encontrado!${NC}"
    echo "Instale com: npm i -g @railway/cli"
    exit 1
fi

# Função para configurar variáveis em um serviço
configure_service_vars() {
    local SERVICE_NAME=$1
    local SERVICE_TYPE=$2  # "web" ou "worker"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔧 Configurando: ${SERVICE_NAME} (${SERVICE_TYPE})${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Selecionar serviço
    if ! railway service "$SERVICE_NAME" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Serviço '${SERVICE_NAME}' não encontrado. Pulando...${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📝 Configurando variáveis básicas...${NC}"
    
    # Variáveis de ambiente
    railway variables set RAILS_ENV=production 2>&1 | grep -v "already exists" || true
    railway variables set NODE_ENV=production 2>&1 | grep -v "already exists" || true
    railway variables set INSTALLATION_ENV=railway 2>&1 | grep -v "already exists" || true
    
    # Logs
    railway variables set RAILS_LOG_TO_STDOUT=true 2>&1 | grep -v "already exists" || true
    railway variables set LOG_LEVEL=info 2>&1 | grep -v "already exists" || true
    railway variables set LOG_SIZE=500 2>&1 | grep -v "already exists" || true
    
    # Performance
    railway variables set RAILS_MAX_THREADS=5 2>&1 | grep -v "already exists" || true
    railway variables set POSTGRES_STATEMENT_TIMEOUT=600s 2>&1 | grep -v "already exists" || true
    
    # Storage
    railway variables set ACTIVE_STORAGE_SERVICE=local 2>&1 | grep -v "already exists" || true
    
    # Account
    railway variables set ENABLE_ACCOUNT_SIGNUP=false 2>&1 | grep -v "already exists" || true
    
    # Push
    railway variables set ENABLE_PUSH_RELAY_SERVER=true 2>&1 | grep -v "already exists" || true
    
    echo -e "${GREEN}✅ Variáveis básicas configuradas${NC}"
    echo ""
    
    # Configurar PostgreSQL
    echo -e "${BLUE}🗄️  Configurando PostgreSQL...${NC}"
    
    # Tentar diferentes nomes de serviço PostgreSQL
    for PG_SERVICE in "pgvector" "Postgres" "PostgreSQL" "postgres"; do
        if railway variables set POSTGRES_HOST="\${{${PG_SERVICE}.PGHOST}}" 2>&1 | grep -q "Variable set"; then
            echo -e "${GREEN}✅ PostgreSQL configurado usando serviço: ${PG_SERVICE}${NC}"
            
            railway variables set POSTGRES_USERNAME="\${{${PG_SERVICE}.PGUSER}}" 2>&1 | grep -v "already exists" || true
            railway variables set POSTGRES_PASSWORD="\${{${PG_SERVICE}.PGPASSWORD}}" 2>&1 | grep -v "already exists" || true
            railway variables set POSTGRES_DATABASE="\${{${PG_SERVICE}.PGDATABASE}}" 2>&1 | grep -v "already exists" || true
            railway variables set DATABASE_URL="\${{${PG_SERVICE}.DATABASE_URL}}" 2>&1 | grep -v "already exists" || true
            break
        fi
    done
    
    echo ""
    
    # Configurar Redis
    echo -e "${BLUE}🔴 Configurando Redis...${NC}"
    
    if railway variables set REDIS_URL="\${{Redis.REDIS_URL}}" 2>&1 | grep -q "Variable set\|already exists"; then
        echo -e "${GREEN}✅ Redis configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  Redis não encontrado. Configure manualmente depois.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Serviço ${SERVICE_NAME} configurado!${NC}"
    echo ""
}

# Mostrar status atual
echo -e "${YELLOW}📋 Status atual do Railway:${NC}"
railway status
echo ""

# Perguntar quais serviços configurar
echo -e "${CYAN}Quais serviços você quer configurar?${NC}"
echo ""
echo "1. Todos os serviços (web, worker)"
echo "2. Apenas serviço web"
echo "3. Apenas serviço worker"
echo "4. Serviços customizados (digite os nomes)"
echo ""
read -p "Escolha uma opção (1-4): " OPTION

case $OPTION in
    1)
        echo ""
        echo -e "${BLUE}Configurando todos os serviços...${NC}"
        echo ""
        
        # Tentar encontrar serviços web e worker
        configure_service_vars "web" "web" || echo -e "${YELLOW}Serviço 'web' não encontrado${NC}"
        configure_service_vars "worker" "worker" || echo -e "${YELLOW}Serviço 'worker' não encontrado${NC}"
        ;;
    2)
        echo ""
        read -p "Nome do serviço web (padrão: web): " WEB_SERVICE
        WEB_SERVICE=${WEB_SERVICE:-web}
        configure_service_vars "$WEB_SERVICE" "web"
        ;;
    3)
        echo ""
        read -p "Nome do serviço worker (padrão: worker): " WORKER_SERVICE
        WORKER_SERVICE=${WORKER_SERVICE:-worker}
        configure_service_vars "$WORKER_SERVICE" "worker"
        ;;
    4)
        echo ""
        read -p "Digite os nomes dos serviços separados por espaço: " SERVICES
        for SERVICE in $SERVICES; do
            read -p "Tipo do serviço '$SERVICE' (web/worker): " SERVICE_TYPE
            configure_service_vars "$SERVICE" "${SERVICE_TYPE:-web}"
        done
        ;;
    *)
        echo -e "${RED}Opção inválida!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  IMPORTANTE: Configure manualmente as seguintes variáveis:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
echo -e "${GREEN}✅ Configuração automática concluída!${NC}"
echo ""
