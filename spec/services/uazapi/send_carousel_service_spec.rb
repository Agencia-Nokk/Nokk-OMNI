require 'rails_helper'

RSpec.describe Uazapi::SendCarouselService do
  let(:account) { create(:account) }
  let(:uazapi_channel) { create(:channel_uazapi, account: account) }
  let!(:inbox) { create(:inbox, channel: uazapi_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511999887766') }
  let(:conversation) { create(:conversation, inbox: inbox, contact_inbox: contact_inbox, account: account, contact: contact) }

  let!(:product1) { create(:shop_product, account: account, name: 'Product 1', price: 100.0) }
  let!(:product2) { create(:shop_product, account: account, name: 'Product 2', price: 200.0) }

  describe '#perform' do
    context 'with valid inputs' do
      before do
        allow_any_instance_of(Uazapi::ProviderService).to receive(:send_carousel).and_return(
          { success: true, message_id: 'CAROUSEL123' }
        )
      end

      it 'sends carousel and creates message' do
        result = described_class.new(
          conversation: conversation,
          product_ids: [product1.id, product2.id]
        ).perform

        expect(result[:success]).to be true
        expect(result[:message]).to be_a(Message)
        expect(result[:message].content_attributes['interactive_type']).to eq('carousel')
      end

      it 'uses default carousel text when not provided' do
        expect_any_instance_of(Uazapi::ProviderService).to receive(:send_carousel)
          .with(anything, hash_including(text: I18n.t('uazapi.shop.carousel.default_text')))

        described_class.new(
          conversation: conversation,
          product_ids: [product1.id]
        ).perform
      end

      it 'uses custom text when provided' do
        custom_text = 'Confira estas ofertas!'
        expect_any_instance_of(Uazapi::ProviderService).to receive(:send_carousel)
          .with(anything, hash_including(text: custom_text))

        described_class.new(
          conversation: conversation,
          product_ids: [product1.id],
          text: custom_text
        ).perform
      end

      it 'creates message with carousel data' do
        result = described_class.new(
          conversation: conversation,
          product_ids: [product1.id, product2.id]
        ).perform

        cards = result[:message].content_attributes.dig('interactive_data', 'cards')
        expect(cards.count).to eq(2)
        expect(cards.first['body']).to include('Product 1')
      end
    end

    context 'with invalid inputs' do
      it 'returns error when conversation not found' do
        result = described_class.new(
          conversation: nil,
          product_ids: [product1.id]
        ).perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('uazapi.shop.errors.conversation_not_found'))
      end

      it 'returns error when channel is not UAZAPI' do
        web_channel = create(:channel_widget, account: account)
        web_inbox = create(:inbox, channel: web_channel, account: account)
        web_conversation = create(:conversation, inbox: web_inbox, account: account)

        result = described_class.new(
          conversation: web_conversation,
          product_ids: [product1.id]
        ).perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('uazapi.shop.errors.channel_not_uazapi'))
      end

      it 'returns error when no products selected' do
        result = described_class.new(
          conversation: conversation,
          product_ids: []
        ).perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('uazapi.shop.errors.no_products_selected'))
      end

      it 'returns error when more than 10 products' do
        product_ids = 11.times.map { create(:shop_product, account: account).id }

        result = described_class.new(
          conversation: conversation,
          product_ids: product_ids
        ).perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('uazapi.shop.errors.max_products_exceeded'))
      end

      it 'returns error when no products found' do
        result = described_class.new(
          conversation: conversation,
          product_ids: [999_999]
        ).perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('uazapi.shop.errors.no_products_found'))
      end
    end

    context 'when provider service fails' do
      before do
        allow_any_instance_of(Uazapi::ProviderService).to receive(:send_carousel).and_return(
          { success: false, error: 'API Error' }
        )
      end

      it 'returns error from provider' do
        result = described_class.new(
          conversation: conversation,
          product_ids: [product1.id]
        ).perform

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API Error')
      end
    end
  end

  describe '#format_price' do
    let(:service) do
      described_class.new(
        conversation: conversation,
        product_ids: [product1.id]
      )
    end

    it 'formats price in Brazilian currency' do
      result = service.send(:format_price, 99.90)
      expect(result).to eq('R$ 99,90')
    end

    it 'returns i18n consult text for zero price' do
      result = service.send(:format_price, 0)
      expect(result).to eq(I18n.t('uazapi.shop.price.consult'))
    end

    it 'returns i18n consult text for nil price' do
      result = service.send(:format_price, nil)
      expect(result).to eq(I18n.t('uazapi.shop.price.consult'))
    end
  end

  describe '#build_buttons' do
    let(:service) do
      described_class.new(
        conversation: conversation,
        product_ids: [product1.id]
      )
    end

    it 'creates view in store button with i18n text' do
      buttons = service.send(:build_buttons, product1)
      view_button = buttons.find { |b| b[:type] == 'URL' }

      expect(view_button[:text]).to eq(I18n.t('uazapi.shop.buttons.view_in_store'))
    end

    it 'creates add to cart button with i18n text' do
      buttons = service.send(:build_buttons, product1)
      cart_button = buttons.find { |b| b[:type] == 'REPLY' }

      expect(cart_button[:text]).to eq(I18n.t('uazapi.shop.buttons.add_to_cart'))
      expect(cart_button[:id]).to eq("ADD_CART_#{product1.id}")
    end
  end
end
