# Nokk-OMNI

Fork customizado do Chatwoot com recursos adicionais do Captain/Copilot.

## Requisitos

- Ruby 3.4.4
- Node.js 24.x
- pnpm 10.x
- PostgreSQL 16+ (com pgvector)
- Redis

## Setup

```bash
# Instalar dependências Ruby
bundle install

# Instalar dependências Node
pnpm install

# Configurar banco de dados
cp .env.example .env
# Edite .env com suas configurações
bundle exec rails db:create db:migrate
```

## Desenvolvimento

```bash
# Iniciar servidor de desenvolvimento
pnpm dev
# ou
overmind start -f Procfile.dev
```

## Build de Produção

```bash
# Instalar dependências
bundle install && pnpm install

# Compilar assets
SECRET_KEY_BASE=precompile_placeholder RAILS_ENV=production bundle exec rake assets:precompile
```

## Testes

```bash
# Testes Ruby
bundle exec rspec

# Teste específico
bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER

# Testes JavaScript
pnpm test
```

## Lint

```bash
# JavaScript/Vue
pnpm eslint
pnpm eslint:fix

# Ruby
bundle exec rubocop -a
```

## Docker

```bash
# Build da imagem
docker build -f docker/Dockerfile -t nokk-omni .

# Desenvolvimento com Docker Compose
docker compose up
```

## Deploy (Railway)

O deploy é feito automaticamente via Railway usando o Dockerfile em `docker/Dockerfile`.

Configuração em `railway.json`:
- Builder: DOCKERFILE
- Dockerfile: `docker/Dockerfile`
- Start command: `bundle exec rails server`
- Pre-deploy: `bundle exec rails db:chatwoot_prepare`

## Estrutura

```
app/                    # Código Rails principal
enterprise/             # Recursos Enterprise (Captain, Copilot, etc.)
docker/                 # Dockerfiles
config/                 # Configurações Rails
```

## Documentação

- [Copilot Tools](docs/copilot-tools.md) - Documentação das ferramentas do Copilot
- [Chatwoot Docs](https://www.chatwoot.com/docs) - Documentação oficial do Chatwoot
