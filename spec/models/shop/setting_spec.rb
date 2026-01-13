require 'rails_helper'

RSpec.describe Shop::Setting do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    subject { build(:shop_setting) }

    it { is_expected.to validate_numericality_of(:products_per_page).only_integer.is_greater_than(0).is_less_than_or_equal_to(48) }
    it { is_expected.to validate_numericality_of(:products_per_row).only_integer.is_greater_than_or_equal_to(2).is_less_than_or_equal_to(4) }
    it { is_expected.to validate_inclusion_of(:default_sort).in_array(Shop::Setting::SORT_OPTIONS) }
    it { is_expected.to validate_inclusion_of(:header_style).in_array(Shop::Setting::HEADER_STYLES) }
    it { is_expected.to validate_inclusion_of(:card_style).in_array(Shop::Setting::CARD_STYLES) }

    describe 'whatsapp_number format' do
      it 'accepts valid phone numbers' do
        setting = build(:shop_setting, whatsapp_number: '+5511999999999')
        expect(setting).to be_valid
      end

      it 'rejects invalid phone numbers' do
        setting = build(:shop_setting, whatsapp_number: 'invalid')
        expect(setting).not_to be_valid
      end

      it 'allows blank' do
        setting = build(:shop_setting, whatsapp_number: '')
        expect(setting).to be_valid
      end
    end

    describe 'contact_email format' do
      it 'accepts valid emails' do
        setting = build(:shop_setting, contact_email: 'test@example.com')
        expect(setting).to be_valid
      end

      it 'rejects invalid emails' do
        setting = build(:shop_setting, contact_email: 'invalid-email')
        expect(setting).not_to be_valid
      end

      it 'allows blank' do
        setting = build(:shop_setting, contact_email: '')
        expect(setting).to be_valid
      end
    end

    describe 'color format validations' do
      %i[primary_color background_color text_color secondary_color].each do |color_field|
        it "accepts valid hex color for #{color_field}" do
          setting = build(:shop_setting, color_field => '#FF5733')
          expect(setting).to be_valid
        end

        it "rejects invalid color format for #{color_field}" do
          setting = build(:shop_setting, color_field => 'invalid')
          expect(setting).not_to be_valid
        end

        it "allows blank for #{color_field}" do
          setting = build(:shop_setting, color_field => '')
          expect(setting).to be_valid
        end
      end
    end

    describe 'minimum_order_value' do
      it 'accepts positive values' do
        setting = build(:shop_setting, minimum_order_value: 50.0)
        expect(setting).to be_valid
      end

      it 'accepts nil' do
        setting = build(:shop_setting, minimum_order_value: nil)
        expect(setting).to be_valid
      end

      it 'rejects negative values' do
        setting = build(:shop_setting, minimum_order_value: -10.0)
        expect(setting).not_to be_valid
      end
    end
  end

  describe '#display_name' do
    it 'returns shop name when present' do
      setting = build(:shop_setting, name: 'My Shop')

      expect(setting.display_name).to eq('My Shop')
    end

    it 'returns account name when shop name is blank' do
      account = create(:account, name: 'Test Account')
      setting = build(:shop_setting, account: account, name: nil)

      expect(setting.display_name).to eq('Test Account')
    end
  end

  describe '#whatsapp_url_number' do
    it 'returns cleaned phone number' do
      setting = build(:shop_setting, whatsapp_number: '+55 (11) 99999-9999')

      expect(setting.whatsapp_url_number).to eq('5511999999999')
    end

    it 'returns nil when whatsapp_number is blank' do
      setting = build(:shop_setting, whatsapp_number: nil)

      expect(setting.whatsapp_url_number).to be_nil
    end
  end

  describe '#online?' do
    it 'returns true when enabled' do
      setting = build(:shop_setting, enabled: true)

      expect(setting.online?).to be true
    end

    it 'returns false when disabled' do
      setting = build(:shop_setting, :disabled)

      expect(setting.online?).to be false
    end
  end

  describe 'constants' do
    it 'defines SORT_OPTIONS' do
      expect(Shop::Setting::SORT_OPTIONS).to eq(%w[newest oldest price_asc price_desc name_asc name_desc])
    end

    it 'defines HEADER_STYLES' do
      expect(Shop::Setting::HEADER_STYLES).to eq(%w[minimal with_banner])
    end

    it 'defines CARD_STYLES' do
      expect(Shop::Setting::CARD_STYLES).to eq(%w[shadow border minimal])
    end
  end
end
