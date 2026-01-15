# Plano de Implementação: Canal UAZAPI

> Branch: `feat/uazapi-channel`
> Base: `Nokk-main`

---

## Referência Rápida da API UAZAPI

### Autenticação
```
Header: token: <api_token>
```

### Endpoints de Envio

| Endpoint | Método | Campos Obrigatórios |
|----------|--------|---------------------|
| `/send/text` | POST | `number`, `text` |
| `/send/media` | POST | `number`, `type`, `file` |
| `/send/contact` | POST | `number`, `fullName`, `phoneNumber` |
| `/send/location` | POST | `number`, `latitude`, `longitude` |

### Tipos de Mídia (`/send/media`)

| Tipo | Descrição | Suporta Caption (`text`) |
|------|-----------|--------------------------|
| `image` | Imagens JPG/PNG | ✅ Sim |
| `video` | Vídeos MP4 | ✅ Sim |
| `document` | PDF, DOCX, etc | ✅ Sim (+ `docName`) |
| `audio` | Arquivo de áudio | ❌ Não |
| `ptt` | Mensagem de voz | ❌ Não |
| `myaudio` | Áudio gravado | ❌ Não |
| `sticker` | Figurinha WebP | ❌ Não |

### Webhook - Campos da Mensagem Recebida

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | string | ID interno UAZAPI |
| `messageid` | string | ID original WhatsApp |
| `chatid` | string | Ex: `5511999999999@s.whatsapp.net` |
| `fromMe` | boolean | `true` se enviada por nós |
| `messageType` | string | `text`, `image`, `video`, `audio`, `document`, `location` |
| `senderName` | string | Nome do remetente |
| `text` | string | Conteúdo de texto/caption |
| `fileURL` | string | URL para download de mídia |
| `status` | string | `pending`, `sent`, `delivered`, `read`, `failed` |

### Chat/Contato - Campos Disponíveis (`/chat/details`)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `image` | string | URL da foto de perfil (full) |
| `imagePreview` | string | URL da foto de perfil (miniatura) |
| `wa_name` | string | Nome no WhatsApp |
| `wa_contactName` | string | Nome salvo nos contatos |
| `name` | string | Nome exibido |
| `phone` | string | Telefone formatado |

### Webhook - Eventos

| Evento | Descrição |
|--------|-----------|
| `messages` | Nova mensagem recebida |
| `messages_update` | Status atualizado (delivered/read) |
| `connection` | Estado da conexão alterado |
| `presence` | Digitando/Online/Offline |

---

## Visão Geral

Criar um canal nativo de WhatsApp via UAZAPI no Nokk-OMNI, seguindo os padrões existentes do Chatwoot para canais WhatsApp (360Dialog, Cloud API).

---

## Fase 1: Infraestrutura Base

### 1.1 Migration - Tabela do Canal

**Arquivo:** `db/migrate/XXXXXX_create_channel_uazapi.rb`

```ruby
class CreateChannelUazapi < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_uazapi do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false
      t.string :provider, default: 'uazapi'
      t.jsonb :provider_config, default: {}
      # provider_config armazena:
      # - api_url: URL da instância UAZAPI
      # - api_token: Token da instância
      # - instance_id: ID da instância
      # - webhook_verify_token: Token para verificar webhooks

      t.timestamps
    end

    add_index :channel_uazapi, :phone_number, unique: true
    add_index :channel_uazapi, :account_id
  end
end
```

### 1.2 Model - Channel::Uazapi

**Arquivo:** `app/models/channel/uazapi.rb`

```ruby
class Channel::Uazapi < ApplicationRecord
  include Channelable

  self.table_name = 'channel_uazapi'

  EDITABLE_ATTRS = [
    :phone_number,
    { provider_config: [:api_url, :api_token, :instance_id, :webhook_verify_token] }
  ].freeze

  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  def name
    'UAZAPI'
  end

  def provider_service
    Uazapi::ProviderService.new(channel: self)
  end

  delegate :send_message, :send_template, :media_url, :api_headers, to: :provider_service

  def api_url
    provider_config['api_url']
  end

  def api_token
    provider_config['api_token']
  end

  def instance_id
    provider_config['instance_id']
  end

  private

  def validate_provider_config
    return if provider_config.blank?

    errors.add(:provider_config, 'api_url is required') if provider_config['api_url'].blank?
    errors.add(:provider_config, 'api_token is required') if provider_config['api_token'].blank?
  end
end
```

### 1.3 Adicionar ao Inbox Model

**Arquivo:** `app/models/inbox.rb` (modificar)

Adicionar `Channel::Uazapi` à lista de tipos de canal suportados.

### 1.4 Routes

**Arquivo:** `config/routes.rb` (adicionar)

```ruby
# Webhooks UAZAPI
post 'webhooks/uazapi/:phone_number', to: 'webhooks/uazapi#process_payload'
get 'webhooks/uazapi/:phone_number', to: 'webhooks/uazapi#verify'

# API para gerenciar canal
namespace :api, defaults: { format: 'json' } do
  namespace :v1 do
    namespace :accounts do
      resources :accounts, only: [] do
        namespace :uazapi do
          resources :channels, only: [:create, :update, :destroy]
        end
      end
    end
  end
end
```

---

## Fase 2: Serviço de Envio (Outgoing)

### 2.1 Provider Service

**Arquivo:** `app/services/uazapi/provider_service.rb`

```ruby
class Uazapi::ProviderService
  def initialize(channel:)
    @channel = channel
  end

  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_url}/send/text",
      headers: api_headers,
      body: {
        number: phone_number,
        text: message.content,
        delay: 1000,
        readchat: true,
        track_source: 'chatwoot',
        track_id: message.id.to_s
      }.to_json
    )
    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = attachment_type(attachment.file_type)

    body = {
      number: phone_number,
      type: type,
      file: attachment.download_url,
      text: message.content,  # UAZAPI usa 'text' para caption
      delay: 1000,
      track_source: 'chatwoot',
      track_id: message.id.to_s
    }

    # Áudio/PTT não suporta caption
    body.delete(:text) if %w[audio ptt myaudio].include?(type)

    # Documento precisa do nome do arquivo
    body[:docName] = attachment.file.filename.to_s if type == 'document'

    response = HTTParty.post(
      "#{api_url}/send/media",
      headers: api_headers,
      body: body.to_json
    )
    process_response(response)
  end

  def api_headers
    {
      'Content-Type' => 'application/json',
      'token' => @channel.api_token
    }
  end

  def api_url
    @channel.api_url
  end

  private

  def attachment_type(file_type)
    case file_type
    when 'image' then 'image'
    when 'audio' then 'ptt'  # Mensagem de voz (Push-to-Talk)
    when 'video' then 'video'
    else 'document'
    end
  end

  # Tipos suportados pela UAZAPI:
  # - image: Imagens (JPG, PNG)
  # - video: Vídeos (MP4)
  # - document: Documentos (PDF, DOCX, etc)
  # - audio: Áudio como arquivo (MP3/OGG)
  # - ptt: Push-to-Talk (mensagem de voz) ← RECOMENDADO para áudio
  # - myaudio: Alternativa ao PTT
  # - sticker: Figurinhas (WebP)

  def process_response(response)
    return nil unless response.success?

    body = JSON.parse(response.body)
    body['id'] || body['messageId']
  rescue StandardError
    nil
  end
end
```

### 2.2 Send On Uazapi Service

**Arquivo:** `app/services/uazapi/send_on_uazapi_service.rb`

```ruby
class Uazapi::SendOnUazapiService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Uazapi
  end

  def perform_reply
    return if message.content.blank? && message.attachments.blank?

    message_id = channel.send_message(
      contact_phone_number,
      message
    )

    message.update!(source_id: message_id) if message_id.present?
  rescue StandardError => e
    message.update!(status: :failed, external_error: e.message)
    raise
  end

  def contact_phone_number
    message.conversation.contact_inbox.source_id
  end
end
```

### 2.3 Registrar no SendReplyJob

**Arquivo:** `app/jobs/send_reply_job.rb` (modificar)

```ruby
CHANNEL_SERVICES = {
  # ... existing channels ...
  'Channel::Uazapi' => ::Uazapi::SendOnUazapiService
}.freeze
```

---

## Fase 3: Serviço de Recebimento (Incoming)

### 3.1 Webhook Controller

**Arquivo:** `app/controllers/webhooks/uazapi_controller.rb`

```ruby
class Webhooks::UazapiController < ActionController::API
  def verify
    render plain: params[:challenge] || 'OK'
  end

  def process_payload
    Webhooks::UazapiEventsJob.perform_later(
      params.permit!.to_h,
      params[:phone_number]
    )
    head :ok
  end
end
```

### 3.2 Webhook Events Job

**Arquivo:** `app/jobs/webhooks/uazapi_events_job.rb`

```ruby
class Webhooks::UazapiEventsJob < ApplicationJob
  queue_as :default

  def perform(params, phone_number)
    channel = Channel::Uazapi.find_by(phone_number: phone_number)
    return unless channel&.inbox

    # Rotear para o serviço apropriado baseado no evento
    event = params['event']

    case event
    when 'messages'
      Uazapi::IncomingMessageService.new(
        inbox: channel.inbox,
        params: params
      ).perform
    when 'messages_update'
      Uazapi::MessageStatusService.new(
        inbox: channel.inbox,
        params: params
      ).perform
    end
  end
end
```

### 3.3 Incoming Message Service

**Arquivo:** `app/services/uazapi/incoming_message_service.rb`

```ruby
class Uazapi::IncomingMessageService
  def initialize(inbox:, params:)
    @inbox = inbox
    @params = params
    @channel = inbox.channel
  end

  def perform
    return if message_already_processed?
    return if outgoing_message?

    set_contact
    set_conversation
    create_message
    attach_files if has_media?
  end

  private

  def message_data
    @params['data'] || @params
  end

  def message_already_processed?
    @inbox.messages.exists?(source_id: message_id)
  end

  def outgoing_message?
    message_data['fromMe'] == true
  end

  def message_id
    # UAZAPI retorna 'id' (interno) e 'messageid' (WhatsApp original)
    message_data['messageid'] || message_data['id']
  end

  def phone_number
    # Formato: 5511999999999@s.whatsapp.net -> 5511999999999
    (message_data['chatid'] || '').gsub(/@.*/, '')
  end

  def message_type
    # UAZAPI usa 'messageType': text, image, video, document, audio, location, button, list, reaction
    message_data['messageType'] || 'text'
  end

  def message_content
    # UAZAPI usa 'text' tanto para mensagens de texto quanto para captions
    message_data['text'] || ''
  end

  def has_media?
    %w[image video audio document sticker].include?(message_type)
  end

  def sender_name
    # UAZAPI usa 'senderName' para o nome do remetente
    message_data['senderName'] || phone_number
  end

  def set_contact
    @contact = @inbox.contact_inboxes.find_by(source_id: phone_number)&.contact

    unless @contact
      @contact = Contact.create!(
        account: @inbox.account,
        phone_number: "+#{phone_number}",
        name: sender_name  # Usa senderName da UAZAPI
      )
      ContactInbox.create!(
        contact: @contact,
        inbox: @inbox,
        source_id: phone_number
      )

      # Buscar foto e detalhes do contato em background
      Uazapi::ContactDetailsJob.perform_later(@contact.id, @channel.id, phone_number)
    end

    @contact_inbox = @inbox.contact_inboxes.find_by(source_id: phone_number)
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.open.last

    unless @conversation
      @conversation = Conversation.create!(
        account: @inbox.account,
        inbox: @inbox,
        contact: @contact,
        contact_inbox: @contact_inbox
      )
    end
  end

  def create_message
    @message = @conversation.messages.create!(
      account: @inbox.account,
      inbox: @inbox,
      content: message_content,
      message_type: :incoming,
      source_id: message_id,
      sender: @contact
    )
  end

  def attach_files
    return unless has_media?

    # UAZAPI usa 'fileURL' para URL de download de mídia
    file_url = message_data['fileURL']
    return if file_url.blank?

    attachment_file = download_file(file_url)
    return unless attachment_file

    @message.attachments.create!(
      account_id: @inbox.account_id,
      file_type: attachment_file_type,
      file: {
        io: attachment_file,
        filename: attachment_filename,
        content_type: attachment_content_type
      }
    )
  end

  def download_file(url)
    Down.download(url, headers: @channel.api_headers)
  rescue Down::Error => e
    Rails.logger.error "UAZAPI: Failed to download file: #{e.message}"
    nil
  end

  def attachment_file_type
    case message_type
    when 'image' then 'image'
    when 'video' then 'video'
    when 'audio' then 'audio'
    else 'file'
    end
  end

  def attachment_filename
    message_data['filename'] || "#{message_type}_#{Time.current.to_i}"
  end

  def attachment_content_type
    message_data['mimetype'] || 'application/octet-stream'
  end
end
```

### 3.4 Contact Details Job (Buscar Foto do Contato)

**Arquivo:** `app/jobs/uazapi/contact_details_job.rb`

```ruby
class Uazapi::ContactDetailsJob < ApplicationJob
  queue_as :low

  def perform(contact_id, channel_id, phone_number)
    @contact = Contact.find_by(id: contact_id)
    @channel = Channel::Uazapi.find_by(id: channel_id)
    return unless @contact && @channel

    fetch_and_update_contact_details(phone_number)
  end

  private

  def fetch_and_update_contact_details(phone_number)
    response = HTTParty.post(
      "#{@channel.api_url}/chat/details",
      headers: @channel.api_headers,
      body: { number: phone_number, preview: false }.to_json
    )

    return unless response.success?

    data = JSON.parse(response.body)
    update_contact_with_details(data)
  rescue StandardError => e
    Rails.logger.error "UAZAPI ContactDetailsJob error: #{e.message}"
  end

  def update_contact_with_details(data)
    # Atualizar nome se disponível e contato ainda não tem nome
    name = data['wa_name'] || data['wa_contactName'] || data['name']
    if name.present? && @contact.name == @contact.phone_number
      @contact.update!(name: name)
    end

    # Atualizar avatar (foto de perfil)
    update_contact_avatar(data['image']) if data['image'].present?
  end

  def update_contact_avatar(image_url)
    return if image_url.blank?
    return if @contact.avatar.attached?

    avatar_file = Down.download(image_url)
    @contact.avatar.attach(
      io: avatar_file,
      filename: "avatar_#{@contact.id}.jpg",
      content_type: 'image/jpeg'
    )
  rescue Down::Error => e
    Rails.logger.error "UAZAPI: Failed to download avatar: #{e.message}"
  end
end
```

### 3.5 Message Status Service

**Arquivo:** `app/services/uazapi/message_status_service.rb`

```ruby
class Uazapi::MessageStatusService
  def initialize(inbox:, params:)
    @inbox = inbox
    @params = params
  end

  def perform
    return if message_id.blank?

    message = @inbox.messages.find_by(source_id: message_id)
    return unless message

    case status
    when 'sent' then message.update!(status: :sent)
    when 'delivered' then message.update!(status: :delivered)
    when 'read' then message.update!(status: :read)
    when 'failed' then message.update!(status: :failed, external_error: error_message)
    end
  end

  private

  def message_id
    @params.dig('data', 'id') || @params['messageId']
  end

  def status
    @params.dig('data', 'status') || @params['status']
  end

  def error_message
    @params.dig('data', 'error') || 'Unknown error'
  end
end
```

---

## Fase 4: API Controllers

### 4.1 Channels Controller

**Arquivo:** `app/controllers/api/v1/accounts/uazapi/channels_controller.rb`

```ruby
class Api::V1::Accounts::Uazapi::ChannelsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def create
    ActiveRecord::Base.transaction do
      @channel = Channel::Uazapi.create!(channel_params)
      @inbox = Current.account.inboxes.create!(
        name: inbox_name,
        channel: @channel
      )
      setup_uazapi_webhook
    end
    render json: { inbox: @inbox, channel: @channel }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @channel = Channel::Uazapi.find(params[:id])
    @channel.update!(channel_params)
    render json: { channel: @channel }
  end

  def destroy
    @channel = Channel::Uazapi.find(params[:id])
    @channel.inbox.destroy!
    head :ok
  end

  private

  def channel_params
    params.require(:channel).permit(
      :phone_number,
      provider_config: [:api_url, :api_token, :instance_id]
    )
  end

  def inbox_name
    params[:inbox_name] || "WhatsApp - #{params.dig(:channel, :phone_number)}"
  end

  def setup_uazapi_webhook
    webhook_url = "#{ENV.fetch('FRONTEND_URL')}/webhooks/uazapi/#{@channel.phone_number}"

    response = HTTParty.post(
      "#{@channel.api_url}/webhook",
      headers: @channel.api_headers,
      body: {
        enabled: true,
        url: webhook_url,
        events: %w[messages messages_update connection]
      }.to_json
    )

    unless response.success?
      raise "Failed to setup webhook: #{response.body}"
    end
  end

  def check_authorization
    authorize :inbox, :create?
  end
end
```

---

## Fase 5: Frontend (Vue.js)

### 5.1 Componente de Criação do Canal

**Arquivo:** `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Uazapi.vue`

```vue
<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';

const { t } = useI18n();
const store = useStore();

const phoneNumber = ref('');
const apiUrl = ref('');
const apiToken = ref('');
const instanceId = ref('');
const inboxName = ref('');
const isCreating = ref(false);
const error = ref('');

const isValid = computed(() => {
  return phoneNumber.value && apiUrl.value && apiToken.value;
});

const createChannel = async () => {
  isCreating.value = true;
  error.value = '';

  try {
    await store.dispatch('inboxes/createUazapiChannel', {
      phone_number: phoneNumber.value,
      inbox_name: inboxName.value || `WhatsApp - ${phoneNumber.value}`,
      provider_config: {
        api_url: apiUrl.value,
        api_token: apiToken.value,
        instance_id: instanceId.value
      }
    });
    // Redirect to inbox settings
  } catch (err) {
    error.value = err.message;
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <h2 class="text-lg font-medium">{{ t('INBOX_MGMT.ADD.UAZAPI.TITLE') }}</h2>

    <div class="flex flex-col gap-2">
      <label>{{ t('INBOX_MGMT.ADD.UAZAPI.PHONE_NUMBER') }}</label>
      <input
        v-model="phoneNumber"
        type="text"
        placeholder="5511999999999"
        class="border rounded px-3 py-2"
      />
    </div>

    <div class="flex flex-col gap-2">
      <label>{{ t('INBOX_MGMT.ADD.UAZAPI.API_URL') }}</label>
      <input
        v-model="apiUrl"
        type="text"
        placeholder="https://seudominio.uazapi.com"
        class="border rounded px-3 py-2"
      />
    </div>

    <div class="flex flex-col gap-2">
      <label>{{ t('INBOX_MGMT.ADD.UAZAPI.API_TOKEN') }}</label>
      <input
        v-model="apiToken"
        type="password"
        placeholder="Token da instância"
        class="border rounded px-3 py-2"
      />
    </div>

    <div class="flex flex-col gap-2">
      <label>{{ t('INBOX_MGMT.ADD.UAZAPI.INSTANCE_ID') }}</label>
      <input
        v-model="instanceId"
        type="text"
        placeholder="inst_xxxxx (opcional)"
        class="border rounded px-3 py-2"
      />
    </div>

    <div class="flex flex-col gap-2">
      <label>{{ t('INBOX_MGMT.ADD.UAZAPI.INBOX_NAME') }}</label>
      <input
        v-model="inboxName"
        type="text"
        placeholder="Nome da inbox (opcional)"
        class="border rounded px-3 py-2"
      />
    </div>

    <div v-if="error" class="text-red-500 text-sm">
      {{ error }}
    </div>

    <button
      :disabled="!isValid || isCreating"
      class="bg-woot-500 text-white px-4 py-2 rounded disabled:opacity-50"
      @click="createChannel"
    >
      {{ isCreating ? t('INBOX_MGMT.ADD.UAZAPI.CREATING') : t('INBOX_MGMT.ADD.UAZAPI.CREATE') }}
    </button>
  </div>
</template>
```

### 5.2 Traduções

**Arquivo:** `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json` (adicionar)

```json
{
  "UAZAPI": {
    "TITLE": "UAZAPI WhatsApp Channel",
    "DESCRIPTION": "Connect your WhatsApp via UAZAPI",
    "PHONE_NUMBER": "Phone Number",
    "API_URL": "UAZAPI URL",
    "API_TOKEN": "Instance Token",
    "INSTANCE_ID": "Instance ID",
    "INBOX_NAME": "Inbox Name",
    "CREATE": "Create Channel",
    "CREATING": "Creating..."
  }
}
```

---

## Fase 6: Funcionalidades Avançadas (Opcional)

### 6.1 Envio de Menu Interativo

```ruby
# app/services/uazapi/provider_service.rb
def send_menu(phone_number, title, options)
  HTTParty.post(
    "#{api_url}/send/menu",
    headers: api_headers,
    body: {
      number: phone_number,
      type: 'list',
      text: title,
      choices: options.map { |o| { id: o[:id], title: o[:title] } }
    }.to_json
  )
end
```

### 6.2 Botão PIX

```ruby
def send_pix_button(phone_number, amount, pix_key, pix_type = 'EVP')
  HTTParty.post(
    "#{api_url}/send/pix-button",
    headers: api_headers,
    body: {
      number: phone_number,
      amount: amount,
      pixKey: pix_key,
      pixType: pix_type
    }.to_json
  )
end
```

### 6.3 Reações

```ruby
def react_to_message(message_id, emoji)
  HTTParty.post(
    "#{api_url}/message/react",
    headers: api_headers,
    body: {
      id: message_id,
      emoji: emoji
    }.to_json
  )
end
```

---

## Checklist de Implementação

### Fase 1: Base
- [ ] Criar migration `create_channel_uazapi`
- [ ] Criar model `Channel::Uazapi`
- [ ] Adicionar channel type ao `Inbox` model
- [ ] Adicionar routes para webhooks e API

### Fase 2: Envio
- [ ] Criar `Uazapi::ProviderService`
- [ ] Criar `Uazapi::SendOnUazapiService`
- [ ] Registrar no `SendReplyJob`
- [ ] Testar envio de texto
- [ ] Testar envio de imagem
- [ ] Testar envio de áudio
- [ ] Testar envio de vídeo
- [ ] Testar envio de documento

### Fase 3: Recebimento
- [ ] Criar `Webhooks::UazapiController`
- [ ] Criar `Webhooks::UazapiEventsJob`
- [ ] Criar `Uazapi::IncomingMessageService`
- [ ] Criar `Uazapi::MessageStatusService`
- [ ] Testar recebimento de texto
- [ ] Testar recebimento de mídia
- [ ] Testar status de mensagem (delivered/read)

### Fase 4: API
- [ ] Criar `Api::V1::Accounts::Uazapi::ChannelsController`
- [ ] Implementar setup automático de webhook
- [ ] Testar criação de canal via API

### Fase 5: Frontend
- [ ] Criar componente Vue para criação do canal
- [ ] Adicionar traduções
- [ ] Adicionar à lista de canais disponíveis
- [ ] Testar fluxo completo na UI

### Fase 6: Extras (Opcional)
- [ ] Menus interativos
- [ ] Botão PIX
- [ ] Reações
- [ ] Edição de mensagem
- [ ] Deleção de mensagem

---

## Testes

### Testes de Unidade (RSpec)

```ruby
# spec/models/channel/uazapi_spec.rb
RSpec.describe Channel::Uazapi do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_uniqueness_of(:phone_number) }
  end
end

# spec/services/uazapi/provider_service_spec.rb
RSpec.describe Uazapi::ProviderService do
  describe '#send_text_message' do
    it 'sends text message successfully'
  end

  describe '#send_attachment_message' do
    it 'sends image with caption'
    it 'sends audio without caption'
  end
end
```

---

## Variáveis de Ambiente

Nenhuma variável global necessária. Todas as configurações são por canal:
- `api_url`: URL da instância UAZAPI
- `api_token`: Token da instância
- `instance_id`: ID da instância (opcional)

---

## Considerações de Segurança

1. **Token Storage**: Tokens armazenados em `provider_config` (JSONB encrypted at rest)
2. **Webhook Validation**: Verificar origem dos webhooks (IP/token)
3. **Rate Limiting**: Respeitar limites da UAZAPI
4. **Error Handling**: Não expor tokens em logs de erro

---

## Referências

- [UAZAPI OpenAPI Spec](./uazapi-openapi-spec.yaml)
- [Chatwoot WhatsApp Channel](../app/models/channel/whatsapp.rb)
- [Chatwoot Provider Services](../app/services/whatsapp/providers/)
