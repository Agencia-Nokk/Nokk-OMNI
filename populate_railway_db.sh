#!/bin/bash

# Script para fazer dump do banco de dados local e popular no Railway
# Uso: ./populate_railway_db.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Script de População de Banco Railway                      ║${NC}"
echo -e "${BLUE}║   Chatwoot/Nokk OMNI                                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se Railway CLI está instalado
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI não encontrado!${NC}"
    echo "Instale com: npm i -g @railway/cli"
    exit 1
fi

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

# Verificar se está linkado ao Railway
if ! railway status &> /dev/null; then
    echo -e "${RED}❌ Projeto não está linkado ao Railway!${NC}"
    echo "Execute: railway link"
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

echo -e "${GREEN}✅ Configurações detectadas:${NC}"
echo "   Host: ${POSTGRES_HOST}"
echo "   Port: ${POSTGRES_PORT}"
echo "   Database: ${POSTGRES_DATABASE}"
echo "   Username: ${POSTGRES_USERNAME}"
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
DUMP_FILE="${DUMP_DIR}/chatwoot_dump_$(date +%Y%m%d_%H%M%S).sql"

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

# Verificar se o Railway está configurado
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚂 Preparando para restaurar no Railway...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar status do Railway
echo -e "${BLUE}📋 Status do Railway:${NC}"
railway status
echo ""

# Perguntar qual serviço PostgreSQL usar
echo -e "${YELLOW}Qual serviço PostgreSQL você quer usar no Railway?${NC}"
echo "   (geralmente: pgvector, Postgres, ou PostgreSQL)"
read -p "Nome do serviço (padrão: pgvector): " PG_SERVICE
PG_SERVICE=${PG_SERVICE:-pgvector}

echo ""
echo -e "${YELLOW}⚠️  ATENÇÃO: Os dados existentes no Railway serão substituídos!${NC}"
read -p "Confirma a restauração? (s/N): " RESTORE_CONFIRM

if [[ ! "$RESTORE_CONFIRM" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Operação cancelada.${NC}"
    rm -rf "$DUMP_DIR"
    exit 0
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔄 Restaurando dump no Railway...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}⏳ Isso pode levar alguns minutos dependendo do tamanho do banco...${NC}"
echo ""

# Primeiro, habilitar extensão pgvector se necessário
echo -e "${BLUE}📌 Habilitando extensão pgvector...${NC}"
railway run -s "$PG_SERVICE" bash -c "psql \"\$DATABASE_URL\" -c 'CREATE EXTENSION IF NOT EXISTS vector;'" 2>&1 || {
    echo -e "${YELLOW}⚠️  Não foi possível habilitar pgvector automaticamente${NC}"
    echo "   Você pode habilitar manualmente depois"
}

echo ""

# Oferecer opções de restauração
echo -e "${CYAN}Escolha o método de restauração:${NC}"
echo ""
echo "1. Automático via railway run (recomendado para dumps pequenos/médios)"
echo "2. Manual via railway connect (recomendado para dumps grandes)"
echo "3. Mostrar comandos para executar manualmente"
echo ""
read -p "Escolha uma opção (1-3): " RESTORE_METHOD

case $RESTORE_METHOD in
    1)
        echo ""
        echo -e "${BLUE}📤 Restaurando via railway run...${NC}"
        echo -e "${YELLOW}⏳ Isso pode levar alguns minutos...${NC}"
        echo ""
        
        # Tentar restaurar usando railway run com stdin
        if cat "$DUMP_FILE" | railway run -s "$PG_SERVICE" bash -c 'psql "$DATABASE_URL"' 2>&1; then
            echo ""
            echo -e "${GREEN}✅ Dump restaurado com sucesso no Railway!${NC}"
            RESTORE_SUCCESS=true
        else
            echo ""
            echo -e "${RED}❌ Erro ao restaurar via railway run${NC}"
            echo -e "${YELLOW}💡 Tente o método manual (opção 2)${NC}"
            RESTORE_SUCCESS=false
        fi
        ;;
    2)
        echo ""
        echo -e "${BLUE}📤 Restaurando via método manual (railway connect)...${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
        echo "   O arquivo de dump está em: ${DUMP_FILE}"
        echo ""
        echo -e "${BLUE}Este método irá:${NC}"
        echo "   1. Conectar ao Railway PostgreSQL"
        echo "   2. Enviar o dump via stdin para o psql"
        echo ""
        read -p "Pressione Enter para continuar..."
        
        echo ""
        echo -e "${BLUE}Conectando e restaurando dump...${NC}"
        echo -e "${YELLOW}⏳ Isso pode levar alguns minutos...${NC}"
        echo ""
        
        # Usar railway connect com o dump sendo passado via stdin
        # Nota: railway connect pode não suportar stdin diretamente, então vamos usar railway run
        if cat "$DUMP_FILE" | railway run -s "$PG_SERVICE" psql "\$DATABASE_URL" 2>&1; then
            echo ""
            echo -e "${GREEN}✅ Dump restaurado com sucesso no Railway!${NC}"
            RESTORE_SUCCESS=true
        else
            echo ""
            echo -e "${RED}❌ Erro ao restaurar via método manual${NC}"
            echo ""
            echo -e "${YELLOW}💡 Tente executar este comando manualmente:${NC}"
            echo "   cat ${DUMP_FILE} | railway run -s ${PG_SERVICE} psql \"\$DATABASE_URL\""
            echo ""
            RESTORE_SUCCESS=false
        fi
        ;;
    3)
        echo ""
        echo -e "${BLUE}📋 Comandos para executar manualmente:${NC}"
        echo ""
        echo -e "${CYAN}Opção A - Via railway run:${NC}"
        echo "   cat ${DUMP_FILE} | railway run -s ${PG_SERVICE} psql \"\$DATABASE_URL\""
        echo ""
        echo -e "${CYAN}Opção B - Via railway connect:${NC}"
        echo "   1. railway connect ${PG_SERVICE}"
        echo "   2. No psql: \\i ${DUMP_FILE}"
        echo ""
        echo -e "${CYAN}Opção C - Via DATABASE_URL direto:${NC}"
        echo "   1. Obtenha a DATABASE_URL: railway variables"
        echo "   2. Execute: cat ${DUMP_FILE} | psql \"\$DATABASE_URL\""
        echo ""
        RESTORE_SUCCESS=false
        ;;
    *)
        echo -e "${RED}Opção inválida!${NC}"
        RESTORE_SUCCESS=false
        ;;
esac

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
    echo -e "${BLUE}💡 Use os comandos mostrados acima para restaurar manualmente${NC}"
fi

echo ""
echo -e "${BLUE}📝 Próximos passos recomendados:${NC}"
echo ""
echo "   1. Execute as migrations se necessário:"
echo "      railway run bundle exec rails db:migrate"
echo ""
echo "   2. Execute os seeds se necessário:"
echo "      railway run bundle exec rails db:seed"
echo ""
echo "   3. Verifique o status da aplicação:"
echo "      railway logs"
echo ""
echo "   4. Verifique o banco de dados:"
echo "      railway connect ${PG_SERVICE}"
echo ""
