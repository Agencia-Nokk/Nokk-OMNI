# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::UpdateCustomToolService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('update_custom_tool')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('Update an existing custom HTTP tool')
    end
  end

  describe '#parameters' do
    it 'defines tool_id and all updatable parameters' do
      expected_params = %i[tool_id title description endpoint_url http_method param_schema
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
    let!(:tool) do
      create(:captain_custom_tool,
             account: account,
             title: 'Original Title',
             description: 'Original description',
             endpoint_url: 'https://api.example.com/v1',
             enabled: true)
    end

    context 'when tool_id is missing' do
      it 'returns error message' do
        result = service.execute(tool_id: nil, title: 'New Title')
        expect(result).to eq('Tool ID is required')
      end
    end

    context 'when tool is not found' do
      it 'returns not found message' do
        result = service.execute(tool_id: 999, title: 'New Title')
        expect(result).to include('not found')
      end
    end

    context 'when no changes are provided' do
      it 'returns no changes message' do
        result = service.execute(tool_id: tool.id)
        expect(result).to eq('No changes provided')
      end
    end

    context 'when updating title' do
      it 'updates successfully' do
        result = service.execute(tool_id: tool.id, title: 'Updated Title')
        expect(result).to be_a(Hash)
        expect(result['content']).to include('updated successfully')

        tool.reload
        expect(tool.title).to eq('Updated Title')
      end
    end

    context 'when updating multiple fields' do
      it 'updates all provided fields' do
        result = service.execute(
          tool_id: tool.id,
          title: 'New Title',
          description: 'New description',
          enabled: false
        )

        expect(result['content']).to include('updated successfully')
        expect(result['content']).to include('title')
        expect(result['content']).to include('description')
        expect(result['content']).to include('enabled')

        tool.reload
        expect(tool.title).to eq('New Title')
        expect(tool.description).to eq('New description')
        expect(tool.enabled).to be false
      end
    end

    context 'when updating http_method' do
      it 'normalizes to uppercase' do
        service.execute(tool_id: tool.id, http_method: 'post')
        tool.reload
        expect(tool.http_method).to eq('POST')
      end

      it 'rejects invalid method' do
        result = service.execute(tool_id: tool.id, http_method: 'PATCH')
        expect(result).to include('Invalid http_method')
      end
    end

    context 'when updating param_schema' do
      it 'parses JSON string' do
        result = service.execute(
          tool_id: tool.id,
          param_schema: '[{"name": "id", "type": "string", "description": "Record ID", "required": true}]'
        )
        expect(result['content']).to include('updated successfully')

        tool.reload
        expect(tool.param_schema).to be_an(Array)
        expect(tool.param_schema.first['name']).to eq('id')
      end

      it 'rejects invalid JSON' do
        result = service.execute(tool_id: tool.id, param_schema: 'invalid')
        expect(result).to include('Invalid')
      end
    end

    context 'when updating auth_type' do
      it 'updates to bearer auth' do
        result = service.execute(
          tool_id: tool.id,
          auth_type: 'bearer',
          auth_config: '{"token": "secret"}'
        )
        expect(result['content']).to include('updated successfully')

        tool.reload
        expect(tool.auth_type).to eq('bearer')
      end

      it 'rejects invalid auth_type' do
        result = service.execute(tool_id: tool.id, auth_type: 'oauth2')
        expect(result).to include('Invalid auth_type')
      end
    end

    context 'when tool belongs to different account' do
      let(:other_account) { create(:account) }
      let!(:other_tool) { create(:captain_custom_tool, account: other_account) }

      it 'returns not found' do
        result = service.execute(tool_id: other_tool.id, title: 'Hacked')
        expect(result).to include('not found')
      end
    end
  end
end
