# 🔧 Solução Completa: Ruby Version no Railway

## ⚠️ Problema Identificado

O comando `railway run bundle exec ruby -v` está mostrando Ruby 2.6.10 porque:

1. **Você está no serviço `pgvector`** (banco de dados), não no serviço Rails
2. O `railway run` sem especificar serviço pode executar localmente
3. A variável precisa estar configurada no serviço Rails (geralmente `web`)

## ✅ Solução Passo a Passo

### 1. Identificar o Serviço Rails

Primeiro, descubra qual é o nome do seu serviço Rails:

```bash
# Ver status atual
railway status

# Listar serviços (via dashboard ou CLI)
# Geralmente é "web" ou o nome do seu repositório
```

### 2. Selecionar o Serviço Correto

```bash
# Selecionar serviço web (substitua "web" pelo nome do seu serviço Rails)
railway service web
```

### 3. Configurar Variável no Serviço Correto

```bash
# Configurar RAILPACK_RUBY_VERSION no serviço web
railway variables --service web --set "RAILPACK_RUBY_VERSION=3.4.4"

# OU se não funcionar, configure no contexto do serviço:
railway service web
railway variables --set "RAILPACK_RUBY_VERSION=3.4.4"
```

### 4. Verificar Configuração

```bash
# Verificar variáveis do serviço web
railway service web
railway variables --kv | grep RAILPACK_RUBY_VERSION
```

### 5. **IMPORTANTE: Fazer Rebuild**

A variável só terá efeito após reconstruir o serviço:

**Opção A - Via Dashboard (Recomendado):**
1. Acesse Railway Dashboard
2. Vá para o serviço `web`
3. Settings → Deploy → **Redeploy** ou **Rebuild**

**Opção B - Via Git:**
```bash
# Fazer commit vazio para forçar rebuild
git commit --allow-empty -m "chore: rebuild with Ruby 3.4.4"
git push
```

### 6. Verificar Após Rebuild

Após o rebuild completar, verifique:

```bash
# Executar no serviço web
railway service web
railway run bundle exec ruby -v

# Deve mostrar: ruby 3.4.4
```

### 7. Executar Migrations e Seeds

Agora você pode executar os comandos:

```bash
# Selecionar serviço web
railway service web

# Executar migrations
railway run bundle exec rails db:migrate

# Executar seeds
railway run bundle exec rails db:seed
```

## 🎯 Comandos Rápidos

```bash
# 1. Selecionar serviço web
railway service web

# 2. Configurar Ruby version
railway variables --set "RAILPACK_RUBY_VERSION=3.4.4"

# 3. Verificar
railway variables --kv | grep RAILPACK_RUBY_VERSION

# 4. Fazer rebuild (via dashboard ou git push)

# 5. Após rebuild, testar
railway run bundle exec ruby -v
```

## 📝 Notas Importantes

- ⚠️ A variável `RAILPACK_RUBY_VERSION` deve estar no **serviço Rails**, não no `pgvector`
- ⚠️ O rebuild é **obrigatório** para aplicar a mudança
- ⚠️ O `railway run` sem especificar serviço pode executar localmente
- ✅ Sempre especifique o serviço: `railway service web` antes de executar comandos

## 🔍 Troubleshooting

### Se ainda mostrar Ruby 2.6.10:

1. Verifique se está no serviço correto:
   ```bash
   railway status
   # Deve mostrar Service: web (não pgvector)
   ```

2. Verifique se a variável está configurada:
   ```bash
   railway variables --kv | grep RAILPACK_RUBY_VERSION
   ```

3. Force rebuild novamente

4. Verifique os logs do build no Railway Dashboard para ver qual Ruby está sendo usado
