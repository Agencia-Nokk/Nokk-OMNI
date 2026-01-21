#!/bin/bash

# Script para corrigir a versão do Ruby no Railway
# Uso: ./fix_railway_ruby_version.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Corretor de Versão Ruby no Railway                         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se Railway CLI está instalado
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI não encontrado!${NC}"
    echo "Instale com: npm i -g @railway/cli"
    exit 1
fi

# Verificar se está linkado ao Railway
if ! railway status &> /dev/null; then
    echo -e "${RED}❌ Projeto não está linkado ao Railway!${NC}"
    echo "Execute: railway link"
    exit 1
fi

# Ler versão do Ruby do .ruby-version
if [ -f .ruby-version ]; then
    RUBY_VERSION=$(cat .ruby-version | tr -d '[:space:]')
    echo -e "${GREEN}✅ Versão do Ruby no projeto: ${RUBY_VERSION}${NC}"
else
    echo -e "${RED}❌ Arquivo .ruby-version não encontrado!${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Verificando configuração atual...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar variáveis de ambiente atuais
echo -e "${BLUE}📋 Variáveis de ambiente relacionadas ao Ruby:${NC}"
railway variables 2>&1 | grep -i ruby || echo -e "${YELLOW}   Nenhuma variável RAILPACK_RUBY_VERSION encontrada${NC}"
echo ""

# Listar serviços
echo -e "${BLUE}📋 Serviços disponíveis:${NC}"
railway status
echo ""

# Perguntar qual serviço configurar
read -p "Qual serviço você quer configurar? (padrão: web): " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-web}

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚙️  Configurando versão do Ruby...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Selecionar serviço
if [ -n "$SERVICE_NAME" ] && [ "$SERVICE_NAME" != "all" ]; then
    echo -e "${BLUE}Selecionando serviço: ${SERVICE_NAME}${NC}"
    railway service "$SERVICE_NAME" 2>&1 || {
        echo -e "${YELLOW}⚠️  Serviço '${SERVICE_NAME}' não encontrado. Configurando no projeto raiz.${NC}"
    }
fi

# Configurar RAILPACK_RUBY_VERSION
echo ""
echo -e "${BLUE}🔧 Configurando RAILPACK_RUBY_VERSION=${RUBY_VERSION}...${NC}"

# Usar a sintaxe correta do Railway CLI
if railway variables --set "RAILPACK_RUBY_VERSION=${RUBY_VERSION}" 2>&1; then
    echo -e "${GREEN}✅ Variável RAILPACK_RUBY_VERSION configurada com sucesso!${NC}"
else
    echo -e "${YELLOW}⚠️  Erro ao configurar variável. Tentando com serviço específico...${NC}"
    # Tentar com serviço específico se fornecido
    if [ -n "$SERVICE_NAME" ] && [ "$SERVICE_NAME" != "all" ]; then
        railway variables --service "$SERVICE_NAME" --set "RAILPACK_RUBY_VERSION=${RUBY_VERSION}" 2>&1 || {
            echo -e "${YELLOW}⚠️  Configure manualmente via Railway Dashboard${NC}"
        }
    fi
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo ""
echo -e "${BLUE}Para aplicar as mudanças, você precisa:${NC}"
echo ""
echo "   1. Fazer um novo deploy (push para o repositório)"
echo "      OU"
echo "   2. Forçar uma reconstrução no Railway Dashboard"
echo ""
echo -e "${CYAN}Verificar se a variável foi configurada:${NC}"
echo "   railway variables --kv | grep RAILPACK_RUBY_VERSION"
echo ""
echo -e "${CYAN}Para testar localmente antes do deploy:${NC}"
echo "   railway run bundle exec ruby -v"
echo ""
