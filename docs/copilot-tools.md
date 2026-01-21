# Copilot Tools - Documentação

Esta documentação descreve todas as tools disponíveis no Copilot para gerenciamento de recursos do Chatwoot.

---

## Sumário

### Macros
- [list_macros](#list_macros) - Listar macros
- [get_macro](#get_macro) - Obter detalhes de uma macro
- [create_macro](#create_macro) - Criar nova macro
- [update_macro](#update_macro) - Atualizar macro existente
- [delete_macro](#delete_macro) - Deletar macro

### Automation Rules (Regras de Automação)
- [list_automation_rules](#list_automation_rules) - Listar regras de automação
- [get_automation_rule](#get_automation_rule) - Obter detalhes de uma regra
- [create_automation_rule](#create_automation_rule) - Criar nova regra
- [update_automation_rule](#update_automation_rule) - Atualizar regra existente
- [delete_automation_rule](#delete_automation_rule) - Deletar regra

### Agents (Agentes)
- [list_agents](#list_agents) - Listar agentes
- [get_agent](#get_agent) - Obter detalhes de um agente
- [create_agent](#create_agent) - Convidar novo agente
- [update_agent](#update_agent) - Atualizar agente
- [delete_agent](#delete_agent) - Remover agente

### Teams (Times)
- [list_teams](#list_teams) - Listar times
- [get_team](#get_team) - Obter detalhes de um time
- [create_team](#create_team) - Criar novo time
- [update_team](#update_team) - Atualizar time
- [delete_team](#delete_team) - Deletar time

### Labels (Etiquetas)
- [list_labels](#list_labels) - Listar etiquetas
- [get_label](#get_label) - Obter detalhes de uma etiqueta
- [create_label](#create_label) - Criar nova etiqueta
- [update_label](#update_label) - Atualizar etiqueta
- [delete_label](#delete_label) - Deletar etiqueta

### Canned Responses (Respostas Prontas)
- [list_canned_responses](#list_canned_responses) - Listar respostas prontas
- [get_canned_response](#get_canned_response) - Obter detalhes de uma resposta
- [create_canned_response](#create_canned_response) - Criar nova resposta
- [update_canned_response](#update_canned_response) - Atualizar resposta
- [delete_canned_response](#delete_canned_response) - Deletar resposta

### Agent Bots (Robôs)
- [list_agent_bots](#list_agent_bots) - Listar robôs
- [get_agent_bot](#get_agent_bot) - Obter detalhes de um robô
- [create_agent_bot](#create_agent_bot) - Criar novo robô
- [update_agent_bot](#update_agent_bot) - Atualizar robô
- [delete_agent_bot](#delete_agent_bot) - Deletar robô

### Custom Attributes (Atributos Personalizados)
- [list_custom_attributes](#list_custom_attributes) - Listar atributos
- [get_custom_attribute](#get_custom_attribute) - Obter detalhes de um atributo
- [create_custom_attribute](#create_custom_attribute) - Criar novo atributo
- [update_custom_attribute](#update_custom_attribute) - Atualizar atributo
- [delete_custom_attribute](#delete_custom_attribute) - Deletar atributo

### Custom Roles (Funções Personalizadas)
- [list_custom_roles](#list_custom_roles) - Listar funções personalizadas
- [get_custom_role](#get_custom_role) - Obter detalhes de uma função
- [create_custom_role](#create_custom_role) - Criar nova função
- [update_custom_role](#update_custom_role) - Atualizar função
- [delete_custom_role](#delete_custom_role) - Deletar função

---

## Arquivos de Implementação

| Grupo | Arquivo |
|-------|---------|
| **Macros** | |
| list_macros | [`enterprise/app/services/captain/tools/copilot/list_macros_service.rb`](../enterprise/app/services/captain/tools/copilot/list_macros_service.rb) |
| get_macro | [`enterprise/app/services/captain/tools/copilot/get_macro_service.rb`](../enterprise/app/services/captain/tools/copilot/get_macro_service.rb) |
| create_macro | [`enterprise/app/services/captain/tools/copilot/create_macro_service.rb`](../enterprise/app/services/captain/tools/copilot/create_macro_service.rb) |
| update_macro | [`enterprise/app/services/captain/tools/copilot/update_macro_service.rb`](../enterprise/app/services/captain/tools/copilot/update_macro_service.rb) |
| delete_macro | [`enterprise/app/services/captain/tools/copilot/delete_macro_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_macro_service.rb) |
| **Automation Rules** | |
| list_automation_rules | [`enterprise/app/services/captain/tools/copilot/list_automation_rules_service.rb`](../enterprise/app/services/captain/tools/copilot/list_automation_rules_service.rb) |
| get_automation_rule | [`enterprise/app/services/captain/tools/copilot/get_automation_rule_service.rb`](../enterprise/app/services/captain/tools/copilot/get_automation_rule_service.rb) |
| create_automation_rule | [`enterprise/app/services/captain/tools/copilot/create_automation_rule_service.rb`](../enterprise/app/services/captain/tools/copilot/create_automation_rule_service.rb) |
| update_automation_rule | [`enterprise/app/services/captain/tools/copilot/update_automation_rule_service.rb`](../enterprise/app/services/captain/tools/copilot/update_automation_rule_service.rb) |
| delete_automation_rule | [`enterprise/app/services/captain/tools/copilot/delete_automation_rule_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_automation_rule_service.rb) |
| **Agents** | |
| list_agents | [`enterprise/app/services/captain/tools/copilot/list_agents_service.rb`](../enterprise/app/services/captain/tools/copilot/list_agents_service.rb) |
| get_agent | [`enterprise/app/services/captain/tools/copilot/get_agent_service.rb`](../enterprise/app/services/captain/tools/copilot/get_agent_service.rb) |
| create_agent | [`enterprise/app/services/captain/tools/copilot/create_agent_service.rb`](../enterprise/app/services/captain/tools/copilot/create_agent_service.rb) |
| update_agent | [`enterprise/app/services/captain/tools/copilot/update_agent_service.rb`](../enterprise/app/services/captain/tools/copilot/update_agent_service.rb) |
| delete_agent | [`enterprise/app/services/captain/tools/copilot/delete_agent_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_agent_service.rb) |
| **Teams** | |
| list_teams | [`enterprise/app/services/captain/tools/copilot/list_teams_service.rb`](../enterprise/app/services/captain/tools/copilot/list_teams_service.rb) |
| get_team | [`enterprise/app/services/captain/tools/copilot/get_team_service.rb`](../enterprise/app/services/captain/tools/copilot/get_team_service.rb) |
| create_team | [`enterprise/app/services/captain/tools/copilot/create_team_service.rb`](../enterprise/app/services/captain/tools/copilot/create_team_service.rb) |
| update_team | [`enterprise/app/services/captain/tools/copilot/update_team_service.rb`](../enterprise/app/services/captain/tools/copilot/update_team_service.rb) |
| delete_team | [`enterprise/app/services/captain/tools/copilot/delete_team_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_team_service.rb) |
| **Labels** | |
| list_labels | [`enterprise/app/services/captain/tools/copilot/list_labels_service.rb`](../enterprise/app/services/captain/tools/copilot/list_labels_service.rb) |
| get_label | [`enterprise/app/services/captain/tools/copilot/get_label_service.rb`](../enterprise/app/services/captain/tools/copilot/get_label_service.rb) |
| create_label | [`enterprise/app/services/captain/tools/copilot/create_label_service.rb`](../enterprise/app/services/captain/tools/copilot/create_label_service.rb) |
| update_label | [`enterprise/app/services/captain/tools/copilot/update_label_service.rb`](../enterprise/app/services/captain/tools/copilot/update_label_service.rb) |
| delete_label | [`enterprise/app/services/captain/tools/copilot/delete_label_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_label_service.rb) |
| **Canned Responses** | |
| list_canned_responses | [`enterprise/app/services/captain/tools/copilot/list_canned_responses_service.rb`](../enterprise/app/services/captain/tools/copilot/list_canned_responses_service.rb) |
| get_canned_response | [`enterprise/app/services/captain/tools/copilot/get_canned_response_service.rb`](../enterprise/app/services/captain/tools/copilot/get_canned_response_service.rb) |
| create_canned_response | [`enterprise/app/services/captain/tools/copilot/create_canned_response_service.rb`](../enterprise/app/services/captain/tools/copilot/create_canned_response_service.rb) |
| update_canned_response | [`enterprise/app/services/captain/tools/copilot/update_canned_response_service.rb`](../enterprise/app/services/captain/tools/copilot/update_canned_response_service.rb) |
| delete_canned_response | [`enterprise/app/services/captain/tools/copilot/delete_canned_response_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_canned_response_service.rb) |
| **Agent Bots** | |
| list_agent_bots | [`enterprise/app/services/captain/tools/copilot/list_agent_bots_service.rb`](../enterprise/app/services/captain/tools/copilot/list_agent_bots_service.rb) |
| get_agent_bot | [`enterprise/app/services/captain/tools/copilot/get_agent_bot_service.rb`](../enterprise/app/services/captain/tools/copilot/get_agent_bot_service.rb) |
| create_agent_bot | [`enterprise/app/services/captain/tools/copilot/create_agent_bot_service.rb`](../enterprise/app/services/captain/tools/copilot/create_agent_bot_service.rb) |
| update_agent_bot | [`enterprise/app/services/captain/tools/copilot/update_agent_bot_service.rb`](../enterprise/app/services/captain/tools/copilot/update_agent_bot_service.rb) |
| delete_agent_bot | [`enterprise/app/services/captain/tools/copilot/delete_agent_bot_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_agent_bot_service.rb) |
| **Custom Attributes** | |
| list_custom_attributes | [`enterprise/app/services/captain/tools/copilot/list_custom_attributes_service.rb`](../enterprise/app/services/captain/tools/copilot/list_custom_attributes_service.rb) |
| get_custom_attribute | [`enterprise/app/services/captain/tools/copilot/get_custom_attribute_service.rb`](../enterprise/app/services/captain/tools/copilot/get_custom_attribute_service.rb) |
| create_custom_attribute | [`enterprise/app/services/captain/tools/copilot/create_custom_attribute_service.rb`](../enterprise/app/services/captain/tools/copilot/create_custom_attribute_service.rb) |
| update_custom_attribute | [`enterprise/app/services/captain/tools/copilot/update_custom_attribute_service.rb`](../enterprise/app/services/captain/tools/copilot/update_custom_attribute_service.rb) |
| delete_custom_attribute | [`enterprise/app/services/captain/tools/copilot/delete_custom_attribute_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_custom_attribute_service.rb) |
| **Custom Roles** | |
| list_custom_roles | [`enterprise/app/services/captain/tools/copilot/list_custom_roles_service.rb`](../enterprise/app/services/captain/tools/copilot/list_custom_roles_service.rb) |
| get_custom_role | [`enterprise/app/services/captain/tools/copilot/get_custom_role_service.rb`](../enterprise/app/services/captain/tools/copilot/get_custom_role_service.rb) |
| create_custom_role | [`enterprise/app/services/captain/tools/copilot/create_custom_role_service.rb`](../enterprise/app/services/captain/tools/copilot/create_custom_role_service.rb) |
| update_custom_role | [`enterprise/app/services/captain/tools/copilot/update_custom_role_service.rb`](../enterprise/app/services/captain/tools/copilot/update_custom_role_service.rb) |
| delete_custom_role | [`enterprise/app/services/captain/tools/copilot/delete_custom_role_service.rb`](../enterprise/app/services/captain/tools/copilot/delete_custom_role_service.rb) |

### Arquivos Relacionados

| Arquivo | Descrição |
|---------|-----------|
| [`enterprise/app/services/captain/copilot/chat_service.rb`](../enterprise/app/services/captain/copilot/chat_service.rb) | Registro das tools no Copilot |
| [`app/javascript/dashboard/components-next/copilot/CopilotEntityCard.vue`](../app/javascript/dashboard/components-next/copilot/CopilotEntityCard.vue) | Componente de cards clicáveis |

---

## Macros

### list_macros

Lista todas as macros disponíveis na conta.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Não | Filtrar por nome (correspondência parcial) |

**Exemplo de uso:**
```
"Liste todas as macros"
"Mostre macros que contenham 'urgente' no nome"
```

**Retorno:** Lista de cards clicáveis com as macros encontradas.

---

### get_macro

Obtém detalhes completos de uma macro específica.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `macro_id` | integer | Sim | ID da macro |

**Exemplo de uso:**
```
"Mostre os detalhes da macro 5"
```

**Retorno:** Detalhes da macro incluindo todas as ações configuradas.

---

### create_macro

Cria uma nova macro com as ações especificadas.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Sim | Nome descritivo para a macro |
| `actions` | string | Sim | JSON array com as ações |

**Ações disponíveis:**
- `send_message` - Enviar mensagem pública
- `add_label` - Adicionar etiqueta
- `remove_label` - Remover etiqueta
- `assign_team` - Atribuir a um time
- `assign_agent` - Atribuir a um agente
- `remove_assigned_team` - Remover time atribuído
- `mute_conversation` - Silenciar conversa
- `change_status` - Mudar status (open/resolved/pending)
- `resolve_conversation` - Resolver conversa
- `snooze_conversation` - Adiar conversa
- `change_priority` - Mudar prioridade (urgent/high/medium/low/none)
- `send_email_transcript` - Enviar transcrição por email
- `add_private_note` - Adicionar nota privada
- `send_webhook_event` - Disparar webhook

**Exemplo de uso:**
```
"Crie uma macro chamada 'Fechar urgente' que adiciona a etiqueta 'resolvido' e resolve a conversa"
```

---

### update_macro

Atualiza uma macro existente.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `macro_id` | integer | Sim | ID da macro |
| `name` | string | Não | Novo nome |
| `actions` | string | Não | Novo JSON array de ações |

**Exemplo de uso:**
```
"Atualize a macro 5 para adicionar também a etiqueta 'vip'"
```

---

### delete_macro

Deleta uma macro da conta.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `macro_id` | integer | Sim | ID da macro |

**Exemplo de uso:**
```
"Delete a macro 5"
```

---

## Automation Rules

### list_automation_rules

Lista todas as regras de automação da conta.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Não | Filtrar por nome |
| `active` | boolean | Não | Filtrar por status ativo |

**Exemplo de uso:**
```
"Liste todas as automações ativas"
```

---

### get_automation_rule

Obtém detalhes de uma regra de automação.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `rule_id` | integer | Sim | ID da regra |

---

### create_automation_rule

Cria uma nova regra de automação.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Sim | Nome da regra |
| `description` | string | Não | Descrição |
| `event_name` | string | Sim | Evento gatilho |
| `conditions` | string | Sim | JSON array de condições |
| `actions` | string | Sim | JSON array de ações |
| `active` | boolean | Não | Se a regra está ativa (padrão: true) |

**Eventos disponíveis:**
- `conversation_created` - Quando uma conversa é criada
- `conversation_updated` - Quando uma conversa é atualizada
- `conversation_opened` - Quando uma conversa é reaberta
- `conversation_resolved` - Quando uma conversa é resolvida
- `message_created` - Quando uma mensagem é criada

**Atributos de condição:**
- `content`, `email`, `country_code`, `status`, `message_type`
- `browser_language`, `assignee_id`, `team_id`, `referer`
- `city`, `company`, `inbox_id`, `mail_subject`, `phone_number`
- `priority`, `conversation_language`, `labels`

**Operadores de filtro:**
- `equal_to`, `not_equal_to`, `contains`, `does_not_contain`
- `is_present`, `is_not_present`, `starts_with`

---

### update_automation_rule

Atualiza uma regra de automação existente.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `rule_id` | integer | Sim | ID da regra |
| `name` | string | Não | Novo nome |
| `description` | string | Não | Nova descrição |
| `event_name` | string | Não | Novo evento |
| `conditions` | string | Não | Novas condições |
| `actions` | string | Não | Novas ações |
| `active` | boolean | Não | Status ativo |

---

### delete_automation_rule

Deleta uma regra de automação.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `rule_id` | integer | Sim | ID da regra |

---

## Agents

### list_agents

Lista todos os agentes da conta.

**Permissão:** Todos os usuários

**Exemplo de uso:**
```
"Liste todos os agentes"
```

---

### get_agent

Obtém detalhes de um agente específico.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `agent_id` | number | Não | ID do agente |
| `name` | string | Não | Nome do agente |
| `email` | string | Não | Email do agente |

---

### create_agent

Convida um novo agente para a conta. Um email de convite será enviado.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `email` | string | Sim | Email do agente |
| `name` | string | Não | Nome do agente |
| `role` | string | Não | Papel: "agent" ou "administrator" |

---

### update_agent

Atualiza informações de um agente.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `agent_id` | number | Sim | ID do agente |
| `name` | string | Não | Novo nome |
| `role` | string | Não | Novo papel |
| `availability` | string | Não | Disponibilidade: "online", "offline", "busy" |
| `auto_offline` | boolean | Não | Auto offline quando inativo |

---

### delete_agent

Remove um agente da conta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `agent_id` | number | Sim | ID do agente |

---

## Teams

### list_teams

Lista todos os times da conta.

**Exemplo de uso:**
```
"Liste todos os times"
```

---

### get_team

Obtém detalhes de um time, incluindo membros.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `team_id` | number | Não | ID do time |
| `name` | string | Não | Nome do time |

---

### create_team

Cria um novo time.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Sim | Nome do time |
| `description` | string | Não | Descrição |
| `allow_auto_assign` | boolean | Não | Habilitar auto-atribuição |
| `member_ids` | string | Não | JSON array de IDs de agentes |

---

### update_team

Atualiza um time existente.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `team_id` | number | Sim | ID do time |
| `name` | string | Não | Novo nome |
| `description` | string | Não | Nova descrição |
| `allow_auto_assign` | boolean | Não | Auto-atribuição |
| `add_member_ids` | string | Não | JSON array de IDs para adicionar |
| `remove_member_ids` | string | Não | JSON array de IDs para remover |

---

### delete_team

Deleta um time.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `team_id` | number | Sim | ID do time |

---

## Labels

### list_labels

Lista todas as etiquetas da conta.

**Permissão:** Administradores e agentes

---

### get_label

Obtém detalhes de uma etiqueta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `label_id` | number | Não | ID da etiqueta |
| `title` | string | Não | Título da etiqueta |

---

### create_label

Cria uma nova etiqueta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `title` | string | Sim | Título (minúsculas, alfanumérico, hífens, underscores) |
| `color` | string | Não | Cor em hexadecimal (ex: #ff0000) |
| `description` | string | Não | Descrição |
| `show_on_sidebar` | boolean | Não | Mostrar na barra lateral |

---

### update_label

Atualiza uma etiqueta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `label_id` | number | Sim | ID da etiqueta |
| `title` | string | Não | Novo título |
| `color` | string | Não | Nova cor |
| `description` | string | Não | Nova descrição |
| `show_on_sidebar` | boolean | Não | Mostrar na barra lateral |

---

### delete_label

Deleta uma etiqueta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `label_id` | number | Sim | ID da etiqueta |

---

## Canned Responses

### list_canned_responses

Lista todas as respostas prontas da conta.

**Permissão:** Administradores e agentes

---

### get_canned_response

Obtém detalhes de uma resposta pronta.

**Permissão:** Administradores e agentes

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `canned_response_id` | number | Não | ID da resposta |
| `short_code` | string | Não | Código de atalho |

---

### create_canned_response

Cria uma nova resposta pronta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `short_code` | string | Sim | Código de atalho (ex: "saudacao") |
| `content` | string | Sim | Conteúdo da mensagem |

**Variáveis suportadas no conteúdo:**
- `{{ contact.name }}` - Nome do contato
- `{{ contact.email }}` - Email do contato
- `{{ conversation.id }}` - ID da conversa

**Exemplo de uso:**
```
"Crie uma resposta pronta com código 'boas_vindas' e conteúdo 'Olá {{ contact.name }}, como posso ajudar?'"
```

---

### update_canned_response

Atualiza uma resposta pronta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `canned_response_id` | number | Sim | ID da resposta |
| `short_code` | string | Não | Novo código |
| `content` | string | Não | Novo conteúdo |

---

### delete_canned_response

Deleta uma resposta pronta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `canned_response_id` | number | Sim | ID da resposta |

---

## Agent Bots

### list_agent_bots

Lista todos os robôs da conta.

---

### get_agent_bot

Obtém detalhes de um robô.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `agent_bot_id` | number | Não | ID do robô |
| `name` | string | Não | Nome do robô |

---

### create_agent_bot

Cria um novo robô.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Sim | Nome do robô |
| `description` | string | Não | Descrição |
| `outgoing_url` | string | Não | URL do webhook |

---

### update_agent_bot

Atualiza um robô.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `agent_bot_id` | number | Sim | ID do robô |
| `name` | string | Não | Novo nome |
| `description` | string | Não | Nova descrição |
| `outgoing_url` | string | Não | Nova URL do webhook |

---

### delete_agent_bot

Deleta um robô.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `agent_bot_id` | number | Sim | ID do robô |

---

## Custom Attributes

### list_custom_attributes

Lista todos os atributos personalizados.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `attribute_model` | string | Não | Filtrar por modelo: "conversation" ou "contact" |

---

### get_custom_attribute

Obtém detalhes de um atributo personalizado.

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `attribute_id` | number | Não | ID do atributo |
| `attribute_key` | string | Não | Chave do atributo |

---

### create_custom_attribute

Cria um novo atributo personalizado.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `attribute_display_name` | string | Sim | Nome de exibição |
| `attribute_key` | string | Sim | Chave única (minúsculas, underscores) |
| `attribute_model` | string | Sim | Modelo: "conversation" ou "contact" |
| `attribute_display_type` | string | Sim | Tipo de exibição |
| `attribute_description` | string | Não | Descrição |
| `attribute_values` | string | Não | JSON array de valores (para tipo list) |

**Tipos de exibição disponíveis:**
- `text` - Campo de texto livre
- `number` - Valor numérico
- `currency` - Valor monetário
- `percent` - Porcentagem
- `link` - URL
- `date` - Seletor de data
- `list` - Lista suspensa (requer attribute_values)
- `checkbox` - Caixa de seleção

**Exemplo de uso:**
```
"Crie um atributo personalizado para conversas chamado 'Prioridade Cliente' do tipo lista com valores Alto, Médio, Baixo"
```

---

### update_custom_attribute

Atualiza um atributo personalizado.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `attribute_id` | number | Sim | ID do atributo |
| `attribute_display_name` | string | Não | Novo nome de exibição |
| `attribute_description` | string | Não | Nova descrição |
| `attribute_values` | string | Não | Novos valores (para tipo list) |

**Nota:** Não é possível alterar `attribute_key` ou `attribute_model` após a criação.

---

### delete_custom_attribute

Deleta um atributo personalizado.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `attribute_id` | number | Sim | ID do atributo |

**Aviso:** Dados existentes em conversas/contatos usando este atributo permanecerão, mas não estarão mais associados a uma definição.

---

## Custom Roles

### list_custom_roles

Lista todas as funções personalizadas da conta.

**Permissão:** Apenas administradores

**Exemplo de uso:**
```
"Liste todas as funções personalizadas"
"Quais custom roles existem?"
```

---

### get_custom_role

Obtém detalhes completos de uma função personalizada, incluindo todas as permissões.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `custom_role_id` | integer | Sim | ID da função personalizada |

**Exemplo de uso:**
```
"Mostre os detalhes da função personalizada 3"
```

---

### create_custom_role

Cria uma nova função personalizada com permissões específicas.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Sim | Nome da função |
| `description` | string | Não | Descrição da função |
| `permissions` | array | Sim | Array de permissões |

**Permissões disponíveis:**
- `conversation_manage` - Pode gerenciar todas as conversas
- `conversation_unassigned_manage` - Pode gerenciar conversas não atribuídas e atribuir a si mesmo
- `conversation_participating_manage` - Pode gerenciar conversas em que está participando
- `contact_manage` - Pode gerenciar contatos
- `report_manage` - Pode gerenciar relatórios
- `knowledge_base_manage` - Pode gerenciar portais de base de conhecimento

**Exemplo de uso:**
```
"Crie uma função personalizada chamada 'Supervisor' com permissões de gerenciar conversas e contatos"
"Crie um custom role 'Analista' que pode ver relatórios e gerenciar conversas não atribuídas"
```

---

### update_custom_role

Atualiza uma função personalizada existente.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `custom_role_id` | integer | Sim | ID da função |
| `name` | string | Não | Novo nome |
| `description` | string | Não | Nova descrição |
| `permissions` | array | Não | Novas permissões |

**Nota:** Atualizar permissões afetará todos os agentes atribuídos a esta função.

**Exemplo de uso:**
```
"Atualize a função 3 para incluir permissão de gerenciar base de conhecimento"
```

---

### delete_custom_role

Deleta uma função personalizada da conta.

**Permissão:** Apenas administradores

**Parâmetros:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `custom_role_id` | integer | Sim | ID da função |

**Nota:** Agentes atribuídos a esta função terão seu custom_role removido (definido como null).

**Exemplo de uso:**
```
"Delete a função personalizada 5"
```

---

## Formato de Retorno

Todas as tools que retornam entidades seguem o padrão:

```ruby
{
  'content' => 'Mensagem descritiva',
  'entities' => [
    {
      'type' => 'tipo_da_entidade',
      'id' => 123,
      'name' => 'Nome da entidade',
      # ... outros campos específicos
    }
  ]
}
```

Os `entities` são renderizados como cards clicáveis no frontend através do componente `CopilotEntityCard.vue`.

### Tipos de Entidade e Rotas

| Tipo | Ícone | Rota |
|------|-------|------|
| `macro` | i-lucide-zap | `/settings/macros/{id}/edit` |
| `automation_rule` | i-lucide-workflow | `/settings/automation/{id}/edit` |
| `agent` | i-lucide-user | `/settings/agents/list` |
| `team` | i-lucide-users | `/settings/teams/list` |
| `label` | i-lucide-tag | `/settings/labels` |
| `canned_response` | i-lucide-message-square-quote | `/settings/canned-response/list` |
| `agent_bot` | i-lucide-bot | `/settings/agent-bots` |
| `custom_attribute` | i-lucide-list-plus | `/settings/custom-attributes/list` |
| `custom_role` | i-lucide-shield-check | `/settings/custom-roles/list` |
