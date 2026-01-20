# Guia de Configuração Railway - Chatwoot/Nokk OMNI

## 📋 Arquivo de Configuração Criado

O arquivo `railway.json` foi criado na raiz do projeto com as configurações básicas.

## 🚀 Passo a Passo para Deploy no Railway

### 1. Criar Projeto no Railway

1. Acesse [railway.app](https://railway.app)
2. Crie um novo projeto
3. Conecte seu repositório Git

### 2. Adicionar Serviços Necessários

#### PostgreSQL (com pgvector) ⚠️ IMPORTANTE

- **NÃO use o PostgreSQL padrão do Railway** - ele não tem pgvector instalado
- Use um dos templates com pgvector pré-instalado:
  - No Railway Dashboard → **New** → **Template**
  - Procure por: **"Postgres with pgVector Engine"** ou **"pgvector-pg18"**
  - Ou use a imagem: `pgvector/pgvector:pg18` ou `pgvector/pgvector:pg16`
- Após criar, habilite a extensão:
  ```sql
  CREATE EXTENSION IF NOT EXISTS vector;
  ```

**Adicionar Volume ao PostgreSQL**:

- Templates do Railway geralmente já incluem volume automaticamente
- Se não aparecer volume, adicione manualmente:
  1. No Dashboard → Clique no serviço PostgreSQL
  2. Abra **Settings** → **Volumes**
  3. Clique **Create Volume** ou **Add Volume**
  4. Mount Path: `/var/lib/postgresql/data` (padrão do PostgreSQL)
  5. Tamanho: escolha conforme necessário (ex: 10GB, 20GB)
- **Nota**: Cada serviço pode ter apenas 1 volume

**Alternativa**: Se já criou PostgreSQL padrão:

1. Exporte seus dados: `pg_dump` (se houver dados)
2. Delete o serviço PostgreSQL atual
3. Crie novo usando template pgvector
4. Restaure os dados (se necessário)

#### Redis

- No Railway Dashboard → **New** → **Database** → **Redis**

### 3. Criar Serviços da Aplicação

#### Serviço Web (Rails)

- **New** → **GitHub Repo** → Selecione seu repositório
- O Railway detectará automaticamente o `railway.json`
- Configure as variáveis de ambiente (veja seção abaixo)

#### Serviço Worker (Sidekiq) - Opcional

- Crie um **novo serviço** apontando para o mesmo repositório
- No dashboard, sobrescreva o **Start Command**:
  ```
  bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
  ```

### 4. Configurar Variáveis de Ambiente

No Railway Dashboard → **Variables**, configure:

#### 🔐 OBRIGATÓRIAS (Segurança)

```bash
# Gerar com: rails secret (ou rake secret)
SECRET_KEY_BASE=seu_secret_key_base_aqui

# Gerar com: rails db:encryption:init
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=chave_primaria_aqui
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=chave_deterministica_aqui
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=salt_aqui
```

#### 🌐 URLs e Ambiente

```bash
# URL pública do Railway (será gerada automaticamente)
FRONTEND_URL=https://seu-projeto.up.railway.app

# Ou se usar domínio customizado:
# FRONTEND_URL=https://chatwoot.seudominio.com

RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=railway
```

#### 🗄️ Banco de Dados (Usar Variáveis do Railway)

```bash
# Railway fornece automaticamente quando você conecta PostgreSQL
POSTGRES_HOST=${{Postgres.PGHOST}}
POSTGRES_USERNAME=${{Postgres.PGUSER}}
POSTGRES_PASSWORD=${{Postgres.PGPASSWORD}}
POSTGRES_DATABASE=${{Postgres.PGDATABASE}}

# Configurações adicionais
RAILS_MAX_THREADS=5
POSTGRES_STATEMENT_TIMEOUT=600s
```

#### 🔴 Redis (Usar Variáveis do Railway)

```bash
# Railway fornece automaticamente quando você conecta Redis
REDIS_URL=${{Redis.REDIS_URL}}

# Se Railway não fornecer URL completa, use:
# REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}
```

#### 📧 Email (SMTP)

```bash
MAILER_SENDER_EMAIL=Chatwoot <noreply@seudominio.com>
SMTP_DOMAIN=seudominio.com
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=seu_email@gmail.com
SMTP_PASSWORD=sua_senha_app
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
```

#### 💾 Storage

```bash
# Opção 1: Local (Railway)
ACTIVE_STORAGE_SERVICE=local

# Opção 2: S3 (Recomendado para produção)
# ACTIVE_STORAGE_SERVICE=s3
# S3_BUCKET_NAME=seu-bucket
# AWS_ACCESS_KEY_ID=sua_key
# AWS_SECRET_ACCESS_KEY=sua_secret
# AWS_REGION=us-east-1
```

#### 📝 Logs

```bash
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info
LOG_SIZE=500
```

#### ⚙️ Outras Configurações

```bash
ENABLE_ACCOUNT_SIGNUP=false
FORCE_SSL=true  # Se usar domínio customizado com HTTPS
ENABLE_PUSH_RELAY_SERVER=true
```

#### 🤖 AI/Captain (Opcional)

```bash
# Se usar features de AI
OPENAI_API_KEY=sk-xxx
# CAPTAIN_OPEN_AI_ENDPOINT=https://api.openai.com/v1
# CAPTAIN_OPEN_AI_MODEL=gpt-4
```

### 5. Habilitar Extensão pgvector no PostgreSQL

⚠️ **IMPORTANTE**: O PostgreSQL padrão do Railway NÃO tem pgvector!

**Solução**: Use um template com pgvector:

1. No Railway Dashboard → **New** → **Template**
2. Busque: **"Postgres with pgVector Engine"** ou **"pgvector-pg18"**
3. Ou crie serviço customizado com imagem: `pgvector/pgvector:pg18`

Após criar com template pgvector, execute:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Via Railway CLI:

**Para serviços customizados (como pgvector Docker)**:
```bash
# Use railway run com DATABASE_URL
railway run psql $DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Ou conectar interativo
railway run psql $DATABASE_URL
# Depois execute: CREATE EXTENSION IF NOT EXISTS vector;
```

**Para serviços PostgreSQL padrão do Railway**:
```bash
railway connect postgres
# No psql:
CREATE EXTENSION IF NOT EXISTS vector;
```

**Se você já criou PostgreSQL padrão (sem pgvector)**:

- Você precisa recriar usando um template pgvector
- Exporte dados primeiro (se houver): `pg_dump`
- Delete o PostgreSQL atual
- Crie novo com template pgvector
- Restaure dados: `psql < dump.sql`

### 6. Deploy

1. Faça commit do `railway.json`
2. Push para o repositório
3. O Railway detectará automaticamente e fará o deploy
4. Acompanhe os logs no dashboard

## 📁 Estrutura de Serviços Recomendada

```
Railway Project
├── PostgreSQL (Database)
│   └── Variáveis: ${{Postgres.*}}
├── Redis (Database)
│   └── Variáveis: ${{Redis.*}}
├── Web Service (Rails)
│   └── Usa: railway.json
│   └── Start: bundle exec rails server -p $PORT
└── Worker Service (Sidekiq) - Opcional
    └── Start: bundle exec sidekiq -C config/sidekiq.yml
```

## 🔧 Comandos Úteis

### Gerar Secrets Localmente

```bash
# SECRET_KEY_BASE
rails secret

# Encryption Keys
rails db:encryption:init
```

### Verificar Deploy

```bash
# Ver logs
railway logs

# Ver variáveis
railway variables

# Conectar ao banco
railway connect postgres
```

## ⚠️ Troubleshooting

### Erro: pgvector não encontrado

```sql
-- Execute no PostgreSQL do Railway
CREATE EXTENSION IF NOT EXISTS vector;
```

### Erro: Build falha

- Verifique se `pnpm` está instalado
- Verifique Node.js version (Railway detecta automaticamente)
- Verifique logs de build no dashboard

### Erro: Migrations falham

- Execute manualmente: `railway run bundle exec rails db:migrate`
- Verifique conexão com PostgreSQL

### Erro: Redis connection

- Verifique se `REDIS_URL` está configurada corretamente
- Use variável `${{Redis.REDIS_URL}}` do Railway

## 📚 Referências

- [Railway Docs](https://docs.railway.com/)
- [Config as Code](https://docs.railway.com/reference/config-as-code)
- [Railway Variables](https://docs.railway.com/guides/variables)

## ✅ Checklist de Deploy

- [ ] Projeto criado no Railway
- [ ] PostgreSQL adicionado e pgvector habilitado
- [ ] Redis adicionado
- [ ] Serviço Web criado e conectado ao repositório
- [ ] Variáveis de ambiente configuradas
- [ ] SECRET_KEY_BASE gerado e configurado
- [ ] Encryption keys geradas e configuradas
- [ ] FRONTEND_URL configurada
- [ ] SMTP configurado (se necessário)
- [ ] Storage configurado (local ou S3)
- [ ] Deploy realizado com sucesso
- [ ] Healthcheck passando
- [ ] Worker configurado (se necessário)
