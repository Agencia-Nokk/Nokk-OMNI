# Setup Local - Nokk OMNI

Guia completo para configurar e rodar a aplicação localmente no macOS.

## Pré-requisitos

- **Ruby** (versão especificada em `.ruby-version`) via rbenv
- **Node.js** e **pnpm**
- **PostgreSQL 16**
- **Redis**
- **Overmind** (gerenciador de processos)

### Instalação dos pré-requisitos

```bash
# Instalar Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar dependências
brew install rbenv postgresql@16 redis overmind pnpm

# Configurar rbenv no shell (adicionar ao ~/.zshrc ou ~/.bashrc)
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc

# Instalar a versão do Ruby do projeto
rbenv install $(cat .ruby-version)
```

---

## 1. Configurar Variáveis de Ambiente

Copie o arquivo de exemplo e configure:

```bash
cp .env.example .env
```

Variáveis importantes no `.env`:

```env
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=sua_senha

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=sua_senha_redis
```

---

## 2. Iniciar Serviços (PostgreSQL e Redis)

```bash
# Iniciar PostgreSQL
brew services start postgresql@16

# Iniciar Redis
brew services start redis
```

### Verificar se estão rodando:

```bash
brew services list
```

---

## 3. Instalar Extensão pgvector (PostgreSQL)

A aplicação usa a extensão `pgvector` para busca vetorial. No macOS com PostgreSQL 16 via Homebrew, é necessário compilar manualmente:

```bash
# Clonar e compilar pgvector
cd /tmp
git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git
cd pgvector

# Definir o caminho do PostgreSQL 16
export PG_CONFIG=/opt/homebrew/opt/postgresql@16/bin/pg_config

# Compilar e instalar
make
make install

# Voltar ao diretório do projeto
cd /caminho/para/Nokk-OMNI
```

---

## 4. Instalar Dependências do Projeto

```bash
# Instalar gems do Ruby
bundle install

# Instalar pacotes Node.js
pnpm install
```

---

## 5. Configurar Banco de Dados

### Reset completo (se necessário):

```bash
# Limpar Redis (com senha)
redis-cli -a sua_senha_redis FLUSHALL

# Dropar e recriar banco PostgreSQL
bundle exec rails db:drop db:create
```

### Rodar migrations e seeds:

```bash
bundle exec rails db:migrate
bundle exec rails db:seed
```

> **Nota:** Se o seed falhar na primeira vez, rode novamente `bundle exec rails db:seed`.

---

## 6. Corrigir Erro de Migration (se necessário)

Se aparecer o erro `ActsAsTaggableOn::Taggable::Cache`:

Edite o arquivo `db/migrate/20231211010807_add_cached_labels_list.rb` e **remova** a linha:

```ruby
ActsAsTaggableOn::Taggable::Cache.included(Conversation)
```

Depois rode novamente:

```bash
bundle exec rails db:migrate
```

---

## 7. Iniciar a Aplicação

```bash
pnpm dev
# ou
overmind start -f Procfile.dev
```

### Se aparecer erro de socket do Overmind:

```bash
rm ./.overmind.sock
pnpm dev
```

### Se a porta estiver em uso:

```bash
# Verificar qual processo está usando a porta 3036 (Vite)
lsof -i :3036

# Matar o processo (substitua PID pelo número)
kill -9 PID
```

---

## 8. Acessar a Aplicação

- **Frontend:** http://localhost:3000
- **Vite Dev Server:** http://localhost:3036

### Credenciais Super Admin (desenvolvimento):

- **Email:** `john@acme.inc`
- **Senha:** `Password1!`

---

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `pnpm dev` | Inicia a aplicação |
| `bundle exec rails c` | Console Rails |
| `bundle exec rails db:migrate` | Rodar migrations |
| `bundle exec rails db:seed` | Popular banco com dados iniciais |
| `bundle exec rspec spec/` | Rodar testes Ruby |
| `pnpm test` | Rodar testes JavaScript |
| `pnpm eslint` | Verificar lint JS/Vue |
| `bundle exec rubocop` | Verificar lint Ruby |

---

## Troubleshooting

### Redis: NOAUTH Authentication required

```bash
redis-cli -a sua_senha_redis FLUSHALL
```

### PostgreSQL: database is being accessed by other users

```bash
brew services restart postgresql@16
```

### pgvector: extension not available

Siga o passo 3 para compilar manualmente a extensão.

### Overmind: socket already exists

```bash
rm ./.overmind.sock
```

---

## Estrutura de Serviços (Procfile.dev)

A aplicação usa múltiplos processos:

- **web:** Servidor Rails (Puma)
- **js:** Vite dev server (frontend Vue.js)
- **worker:** Sidekiq (jobs em background)

Todos são gerenciados pelo Overmind quando você roda `pnpm dev`.
