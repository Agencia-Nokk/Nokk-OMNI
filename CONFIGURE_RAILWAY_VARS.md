# 🔧 Guia de Configuração de Variáveis no Railway

Este guia mostra como configurar as variáveis de ambiente nos serviços do Railway.

## 📋 Serviços Necessários

1. **pgvector** - PostgreSQL com extensão pgvector ✅ (já criado)
2. **Redis** - Serviço de cache e filas
3. **Web** - Serviço Rails (aplicação principal)
4. **Worker** - Serviço Sidekiq (opcional, mas recomendado)

## 🚀 Configuração Rápida

### Método 1: Via Script Automático

```bash
# Configurar serviço web
./configure_railway_vars.sh web

# Configurar serviço worker (se existir)
./configure_railway_vars.sh worker
```

### Método 2: Via Railway CLI (Manual)

#### 1. Selecionar o Serviço

```bash
# Para serviço web
railway service web

# Para serviço worker
railway service worker
```

#### 2. Configurar Variáveis Básicas

```bash
# Ambiente
railway variables set RAILS_ENV=production
railway variables set NODE_ENV=production
railway variables set INSTALLATION_ENV=railway

# Logs
railway variables set RAILS_LOG_TO_STDOUT=true
railway variables set LOG_LEVEL=info
railway variables set LOG_SIZE=500

# Performance
railway variables set RAILS_MAX_THREADS=5
railway variables set POSTGRES_STATEMENT_TIMEOUT=600s

# Storage
railway variables set ACTIVE_STORAGE_SERVICE=local

# Account
railway variables set ENABLE_ACCOUNT_SIGNUP=false

# Push
railway variables set ENABLE_PUSH_RELAY_SERVER=true
```

#### 3. Configurar Banco de Dados (PostgreSQL)

**Importante**: Use as referências do Railway para conectar automaticamente ao serviço `pgvector`:

```bash
# Método 1: Usar referências do Railway (RECOMENDADO)
railway variables set POSTGRES_HOST='${{pgvector.PGHOST}}'
railway variables set POSTGRES_USERNAME='${{pgvector.PGUSER}}'
railway variables set POSTGRES_PASSWORD='${{pgvector.PGPASSWORD}}'
railway variables set POSTGRES_DATABASE='${{pgvector.PGDATABASE}}'
railway variables set DATABASE_URL='${{pgvector.DATABASE_URL}}'

# Se o nome do serviço for diferente, tente:
# ${{Postgres.PGHOST}}
# ${{PostgreSQL.PGHOST}}
```

**Verificar nome do serviço PostgreSQL**:
```bash
railway variables | grep PGHOST
```

#### 4. Configurar Redis

```bash
railway variables set REDIS_URL='${{Redis.REDIS_URL}}'
```

**Verificar nome do serviço Redis**:
```bash
railway variables | grep REDIS
```

#### 5. Variáveis Obrigatórias (Configurar Manualmente)

⚠️ **IMPORTANTE**: Estas variáveis precisam ser configuradas manualmente:

##### SECRET_KEY_BASE (OBRIGATÓRIO)

```bash
# Gerar secret localmente
rails secret

# Configurar no Railway
railway variables set SECRET_KEY_BASE=<valor_gerado>
```

##### Encryption Keys (OBRIGATÓRIO para MFA/2FA)

```bash
# Gerar keys localmente
rails db:encryption:init

# Configurar no Railway
railway variables set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<chave_primaria>
railway variables set ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<chave_deterministica>
railway variables set ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<salt>
```

##### FRONTEND_URL (OBRIGATÓRIO)

```bash
# Obter URL do Railway
railway domain

# Configurar
railway variables set FRONTEND_URL=https://seu-projeto.up.railway.app

# Ou se usar domínio customizado:
railway variables set FRONTEND_URL=https://chatwoot.seudominio.com
```

#### 6. Variáveis Opcionais

##### SMTP (Email)

```bash
railway variables set MAILER_SENDER_EMAIL="Chatwoot <noreply@seudominio.com>"
railway variables set SMTP_DOMAIN=seudominio.com
railway variables set SMTP_ADDRESS=smtp.gmail.com
railway variables set SMTP_PORT=587
railway variables set SMTP_USERNAME=seu_email@gmail.com
railway variables set SMTP_PASSWORD=sua_senha_app
railway variables set SMTP_AUTHENTICATION=plain
railway variables set SMTP_ENABLE_STARTTLS_AUTO=true
railway variables set SMTP_OPENSSL_VERIFY_MODE=peer
```

##### Storage S3 (Opcional - Recomendado para produção)

```bash
railway variables set ACTIVE_STORAGE_SERVICE=s3
railway variables set S3_BUCKET_NAME=seu-bucket
railway variables set AWS_ACCESS_KEY_ID=sua_key
railway variables set AWS_SECRET_ACCESS_KEY=sua_secret
railway variables set AWS_REGION=us-east-1
```

##### AI/Captain (Opcional)

```bash
railway variables set OPENAI_API_KEY=sk-xxx
# railway variables set CAPTAIN_OPEN_AI_ENDPOINT=https://api.openai.com/v1
# railway variables set CAPTAIN_OPEN_AI_MODEL=gpt-4
```

##### SSL

```bash
# Se usar domínio customizado com HTTPS
railway variables set FORCE_SSL=true
```

## 📝 Checklist de Configuração

### Para Serviço Web:

- [ ] `RAILS_ENV=production`
- [ ] `NODE_ENV=production`
- [ ] `INSTALLATION_ENV=railway`
- [ ] `SECRET_KEY_BASE` (gerado)
- [ ] `ACTIVE_RECORD_ENCRYPTION_*` (3 variáveis, geradas)
- [ ] `FRONTEND_URL` (URL do Railway ou customizada)
- [ ] `POSTGRES_HOST` (referência: `${{pgvector.PGHOST}}`)
- [ ] `POSTGRES_USERNAME` (referência: `${{pgvector.PGUSER}}`)
- [ ] `POSTGRES_PASSWORD` (referência: `${{pgvector.PGPASSWORD}}`)
- [ ] `POSTGRES_DATABASE` (referência: `${{pgvector.PGDATABASE}}`)
- [ ] `DATABASE_URL` (referência: `${{pgvector.DATABASE_URL}}`)
- [ ] `REDIS_URL` (referência: `${{Redis.REDIS_URL}}`)
- [ ] `RAILS_MAX_THREADS=5`
- [ ] `POSTGRES_STATEMENT_TIMEOUT=600s`
- [ ] `ACTIVE_STORAGE_SERVICE=local` (ou `s3`)
- [ ] `ENABLE_ACCOUNT_SIGNUP=false`
- [ ] `RAILS_LOG_TO_STDOUT=true`
- [ ] `LOG_LEVEL=info`

### Para Serviço Worker (Sidekiq):

- [ ] Todas as variáveis do serviço Web (exceto `FRONTEND_URL` se não necessário)
- [ ] Mesmas configurações de banco e Redis

## 🔍 Verificar Configuração

```bash
# Ver todas as variáveis de um serviço
railway variables

# Ver variáveis específicas
railway variables | grep POSTGRES
railway variables | grep REDIS
railway variables | grep SECRET_KEY_BASE
```

## 🐛 Troubleshooting

### Erro: Variável não encontrada

Se as referências `${{pgvector.*}}` não funcionarem:

1. Verifique o nome exato do serviço PostgreSQL:
   ```bash
   railway status
   ```

2. Use o nome correto nas referências:
   ```bash
   railway variables set POSTGRES_HOST='${{NomeExatoDoServico.PGHOST}}'
   ```

3. Ou use variáveis diretas (menos recomendado):
   ```bash
   railway variables set POSTGRES_HOST=tramway.proxy.rlwy.net
   railway variables set POSTGRES_USERNAME=postgres
   railway variables set POSTGRES_PASSWORD=<senha>
   ```

### Erro: Redis não encontrado

1. Verifique se o serviço Redis existe:
   ```bash
   railway status
   ```

2. Se não existir, crie:
   - Railway Dashboard → **New** → **Database** → **Redis**

3. Use a referência correta:
   ```bash
   railway variables set REDIS_URL='${{Redis.REDIS_URL}}'
   ```

## 📚 Referências

- [Railway Variables Guide](https://docs.railway.com/guides/variables)
- [Railway Service References](https://docs.railway.com/reference/variables#service-references)
