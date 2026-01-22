# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::CreateCustomToolService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('create_custom_tool')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('Create a new custom HTTP tool')
    end
  end

  describe '#parameters' do
    it 'defines all required and optional parameters' do
      expected_params = %i[title description endpoint_url http_method param_schema
                           auth_type auth_config request_template response_template enabled]
      expect(service.parameters.keys).to contain_exactly(*expected_params)
    end
  end

  describe '#active?' do
    context 'when user is an admin' do
      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user is an agent' do
      let(:user) { create(:user, account: account) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent)
      end

      it 'returns true (agents have default access)' do
        expect(service.active?).to be true
      end
    end

    context 'when user is an agent with custom role without admin permission' do
      let(:user) { create(:user, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: []) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns false' do
        expect(service.active?).to be false
      end
    end
  end

  describe '#execute' do
    let(:valid_params) do
      {
        title: 'ViaCEP Lookup',
        description: 'Consulta endereço por CEP',
        endpoint_url: 'https://viacep.com.br/ws/{{ cep }}/json/'
      }
    end

    context 'when required params are missing' do
      it 'returns error for missing title' do
        result = service.execute(title: '', description: 'Desc', endpoint_url: 'https://api.com')
        expect(result).to eq('Title is required')
      end

      it 'returns error for missing description' do
        result = service.execute(title: 'Title', description: '', endpoint_url: 'https://api.com')
        expect(result).to eq('Description is required')
      end

      it 'returns error for missing endpoint_url' do
        result = service.execute(title: 'Title', description: 'Desc', endpoint_url: '')
        expect(result).to eq('Endpoint URL is required')
      end
    end

    context 'when creating with valid params' do
      it 'creates the tool successfully' do
        expect { service.execute(**valid_params) }.to change(Captain::CustomTool, :count).by(1)
      end

      it 'returns success response with entities' do
        result = service.execute(**valid_params)
        expect(result).to be_a(Hash)
        expect(result['content']).to include('created successfully')
        expect(result['entities']).to be_an(Array)
      end

      it 'sets default values correctly' do
        service.execute(**valid_params)
        tool = Captain::CustomTool.last

        expect(tool.http_method).to eq('GET')
        expect(tool.auth_type).to eq('none')
        expect(tool.enabled).to be true
      end
    end

    context 'when creating with optional params' do
      let(:full_params) do
        valid_params.merge(
          http_method: 'POST',
          param_schema: '[{"name": "cep", "type": "string", "description": "CEP code", "required": true}]',
          auth_type: 'bearer',
          auth_config: '{"token": "secret123"}',
          request_template: '{"cep": "{{ cep }}"}',
          response_template: 'Address: {{ logradouro }}',
          enabled: false
        )
      end

      it 'creates tool with all options' do
        result = service.execute(**full_params)
        expect(result['content']).to include('created successfully')

        tool = Captain::CustomTool.last
        expect(tool.http_method).to eq('POST')
        expect(tool.auth_type).to eq('bearer')
        expect(tool.enabled).to be false
        expect(tool.param_schema).to be_an(Array)
      end
    end

    context 'when tool with same title already exists' do
      before do
        create(:captain_custom_tool, account: account, title: 'ViaCEP Lookup')
      end

      it 'returns existing tool message' do
        result = service.execute(**valid_params)
        expect(result).to be_a(Hash)
        expect(result['content']).to include('already exists')
      end
    end

    context 'when param_schema is invalid JSON' do
      it 'returns error message' do
        result = service.execute(**valid_params.merge(param_schema: 'invalid json'))
        expect(result).to include('Invalid')
      end
    end

    context 'when http_method is invalid' do
      it 'returns error message' do
        result = service.execute(**valid_params.merge(http_method: 'PATCH'))
        expect(result).to include('Invalid http_method')
      end
    end

    context 'when auth_type is invalid' do
      it 'returns error message' do
        result = service.execute(**valid_params.merge(auth_type: 'oauth'))
        expect(result).to include('Invalid auth_type')
      end
    end
  end
end
