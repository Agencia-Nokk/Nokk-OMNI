require 'rails_helper'

RSpec.describe Uazapi::IncomingMessageService do
  let(:account) { create(:account) }
  let(:uazapi_channel) { create(:channel_uazapi, account: account) }
  let!(:inbox) { create(:inbox, channel: uazapi_channel, account: account) }
  let(:phone_number) { '5511999887766' }

  describe '#perform' do
    context 'when valid text message params' do
      let(:params) do
        {
          'message' => {
            'messageid' => 'MSG123456',
            'chatid' => "#{phone_number}@s.whatsapp.net",
            'sender' => "#{phone_number}@s.whatsapp.net",
            'senderName' => 'Test User',
            'text' => 'Hello World',
            'type' => 'text',
            'fromMe' => false,
            'isGroup' => false
          }
        }.with_indifferent_access
      end

      it 'creates contact, conversation and message' do
        expect do
          described_class.new(inbox: inbox, params: params).perform
        end.to change(Contact, :count).by(1)
                                      .and change(Conversation, :count).by(1)
                                                                       .and change(Message, :count).by(1)
      end

      it 'creates contact with correct phone number' do
        described_class.new(inbox: inbox, params: params).perform
        expect(Contact.last.phone_number).to eq("+#{phone_number}")
      end

      it 'creates message with correct content' do
        described_class.new(inbox: inbox, params: params).perform
        expect(Message.last.content).to eq('Hello World')
        expect(Message.last.message_type).to eq('incoming')
      end

      it 'does not create duplicate messages' do
        described_class.new(inbox: inbox, params: params).perform
        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to change(Message, :count)
      end
    end

    context 'when outgoing message from WhatsApp' do
      let(:params) do
        {
          'message' => {
            'messageid' => 'MSG123456',
            'chatid' => "#{phone_number}@s.whatsapp.net",
            'sender' => "#{phone_number}@s.whatsapp.net",
            'text' => 'Sent from phone',
            'type' => 'text',
            'fromMe' => true,
            'isGroup' => false
          }
        }.with_indifferent_access
      end

      it 'creates outgoing message' do
        described_class.new(inbox: inbox, params: params).perform
        expect(Message.last.message_type).to eq('outgoing')
      end
    end

    context 'when message sent from Chatwoot' do
      let(:params) do
        {
          'message' => {
            'messageid' => 'MSG123456',
            'chatid' => "#{phone_number}@s.whatsapp.net",
            'text' => 'Sent from Chatwoot',
            'type' => 'text',
            'fromMe' => true,
            'track_source' => 'chatwoot'
          }
        }.with_indifferent_access
      end

      it 'skips message to avoid duplicates' do
        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to change(Message, :count)
      end
    end

    context 'when group message' do
      let(:group_id) { '123456789@g.us' }
      let(:params) do
        {
          'message' => {
            'messageid' => 'MSG123456',
            'chatid' => group_id,
            'sender' => "#{phone_number}@s.whatsapp.net",
            'senderName' => 'Group Member',
            'text' => 'Hello Group',
            'type' => 'text',
            'fromMe' => false,
            'isGroup' => true
          },
          'chat' => {
            'name' => 'Test Group'
          }
        }.with_indifferent_access
      end

      it 'creates group contact' do
        described_class.new(inbox: inbox, params: params).perform
        contact = Contact.last
        expect(contact.additional_attributes['is_group']).to be true
        expect(contact.name).to eq('Test Group')
      end

      it 'stores group sender info in message' do
        described_class.new(inbox: inbox, params: params).perform
        message = Message.last
        expect(message.content_attributes['is_group_message']).to be true
        expect(message.content_attributes['group_sender_name']).to eq('Group Member')
      end
    end

    context 'when ADD_CART button response' do
      let!(:product) { create(:shop_product, account: account, name: 'Test Product', price: 50.0) }
      let!(:contact_inbox) { create(:contact_inbox, inbox: inbox, source_id: phone_number) }
      let!(:conversation) { create(:conversation, inbox: inbox, contact_inbox: contact_inbox, account: account) }

      let(:params) do
        {
          'message' => {
            'messageid' => 'MSG123456',
            'chatid' => "#{phone_number}@s.whatsapp.net",
            'sender' => "#{phone_number}@s.whatsapp.net",
            'buttonOrListid' => "ADD_CART_#{product.id}",
            'type' => 'text',
            'fromMe' => false,
            'isGroup' => false
          }
        }.with_indifferent_access
      end

      before do
        allow_any_instance_of(Uazapi::ProviderService).to receive(:send_buttons).and_return(
          { success: true, message_id: 'MSG789' }
        )
      end

      it 'creates cart with product' do
        expect do
          described_class.new(inbox: inbox, params: params).perform
        end.to change(Shop::Cart, :count).by(1)
                                         .and change(Shop::CartItem, :count).by(1)
      end

      it 'formats button response with i18n' do
        described_class.new(inbox: inbox, params: params).perform
        message = inbox.messages.find_by(source_id: 'MSG123456')
        expect(message.content).to include(product.name)
      end
    end

    context 'when VIEW_CART button response' do
      let!(:contact) { create(:contact, account: account, phone_number: "+#{phone_number}") }
      let!(:contact_inbox) { create(:contact_inbox, inbox: inbox, source_id: phone_number, contact: contact) }
      let!(:conversation) { create(:conversation, inbox: inbox, contact_inbox: contact_inbox, account: account, contact: contact) }
      let!(:product) { create(:shop_product, account: account, name: 'Cart Product', price: 100.0) }
      let!(:cart) { create(:shop_cart, account: account, conversation: conversation, contact: contact, status: :active) }
      let!(:cart_item) { create(:shop_cart_item, cart: cart, product: product, quantity: 2, unit_price: 100.0) }

      let(:params) do
        {
          'message' => {
            'messageid' => 'MSG123456',
            'chatid' => "#{phone_number}@s.whatsapp.net",
            'sender' => "#{phone_number}@s.whatsapp.net",
            'buttonOrListid' => 'VIEW_CART',
            'type' => 'text',
            'fromMe' => false,
            'isGroup' => false
          }
        }.with_indifferent_access
      end

      before do
        allow_any_instance_of(Uazapi::ProviderService).to receive(:send_buttons).and_return(
          { success: true, message_id: 'MSG789' }
        )
      end

      it 'sends cart details' do
        expect_any_instance_of(Uazapi::ProviderService).to receive(:send_buttons)
        described_class.new(inbox: inbox, params: params).perform
      end
    end

    context 'when CLEAR_CART button response' do
      let!(:contact) { create(:contact, account: account, phone_number: "+#{phone_number}") }
      let!(:contact_inbox) { create(:contact_inbox, inbox: inbox, source_id: phone_number, contact: contact) }
      let!(:conversation) { create(:conversation, inbox: inbox, contact_inbox: contact_inbox, account: account, contact: contact) }
      let!(:product) { create(:shop_product, account: account) }
      let!(:cart) { create(:shop_cart, account: account, conversation: conversation, contact: contact, status: :active) }
      let!(:cart_item) { create(:shop_cart_item, cart: cart, product: product) }

      let(:params) do
        {
          'message' => {
            'messageid' => 'MSG123456',
            'chatid' => "#{phone_number}@s.whatsapp.net",
            'sender' => "#{phone_number}@s.whatsapp.net",
            'buttonOrListid' => 'CLEAR_CART',
            'type' => 'text',
            'fromMe' => false,
            'isGroup' => false
          }
        }.with_indifferent_access
      end

      before do
        allow_any_instance_of(Uazapi::ProviderService).to receive(:send_text).and_return(
          { success: true, message_id: 'MSG789' }
        )
      end

      it 'clears cart items' do
        expect do
          described_class.new(inbox: inbox, params: params).perform
        end.to change { cart.items.count }.from(1).to(0)
      end
    end
  end

  describe '#format_button_response' do
    let(:service) { described_class.new(inbox: inbox, params: {}) }

    it 'formats VIEW_CART with i18n' do
      result = service.send(:format_button_response, 'VIEW_CART')
      expect(result).to eq(I18n.t('uazapi.shop.buttons.view_cart'))
    end

    it 'formats CHECKOUT with i18n' do
      result = service.send(:format_button_response, 'CHECKOUT')
      expect(result).to eq(I18n.t('uazapi.shop.buttons.checkout'))
    end

    it 'formats CLEAR_CART with i18n' do
      result = service.send(:format_button_response, 'CLEAR_CART')
      expect(result).to eq(I18n.t('uazapi.shop.buttons.clear_cart'))
    end

    it 'formats generic button with i18n' do
      result = service.send(:format_button_response, 'CUSTOM_123')
      expect(result).to eq(I18n.t('uazapi.shop.button_response.generic_button', button_id: 'CUSTOM_123'))
    end
  end
end
