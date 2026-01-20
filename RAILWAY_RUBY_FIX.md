# 🔧 Correção da Versão do Ruby no Railway

## Problema
O Railway está usando Ruby 2.6.10, mas o projeto requer Ruby 3.4.4.

## Solução Rápida

### Opção 1: Configurar Variável de Ambiente (Recomendado)

Execute o script fornecido:
```bash
./fix_railway_ruby_version.sh
```

Ou configure manualmente:
```bash
# Configurar a versão do Ruby
railway variables set RAILPACK_RUBY_VERSION=3.4.4

# Verificar se foi configurado
railway variables | grep RAILPACK_RUBY_VERSION
```

**⚠️ IMPORTANTE:** Após configurar, você precisa fazer um novo deploy para que a mudança tenha efeito.

### Opção 2: Forçar Rebuild no Railway Dashboard

1. Acesse o Railway Dashboard
2. Vá para o seu serviço
3. Clique em **Settings** → **Deploy**
4. Clique em **Redeploy** ou **Rebuild**

### Opção 3: Executar Comandos com Ruby Específico (Temporário)

Se você precisa executar comandos AGORA sem esperar o rebuild, pode especificar o Ruby no comando:

```bash
# Para migrations
railway run -s web bash -c "ruby -v && bundle exec rails db:migrate"

# Para seeds  
railway run -s web bash -c "ruby -v && bundle exec rails db:seed"
```

Mas isso ainda pode falhar se o Ruby 3.4.4 não estiver instalado no ambiente.

## Verificação

Após o rebuild, verifique a versão do Ruby:
```bash
railway run bundle exec ruby -v
```

Deve mostrar: `ruby 3.4.4`

## Por que isso acontece?

O Railway RAILPACK detecta a versão do Ruby nesta ordem:
1. `RAILPACK_RUBY_VERSION` (variável de ambiente) ← **Esta tem prioridade**
2. `.ruby-version` (arquivo)
3. `Gemfile` (ruby '3.4.4')
4. Default (3.4.6)

Se não houver `RAILPACK_RUBY_VERSION` configurada e o `.ruby-version` não for detectado corretamente, pode usar uma versão antiga.

## Solução Definitiva

1. Configure `RAILPACK_RUBY_VERSION=3.4.4` via variável de ambiente
2. Faça commit e push do `.ruby-version` (se ainda não fez)
3. Force um rebuild do serviço no Railway
4. Verifique se está usando a versão correta
