# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::DeleteCustomToolService do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('delete_custom_tool')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to include('Delete a custom HTTP tool')
    end
  end

  describe '#parameters' do
    it 'defines tool_id parameter' do
      expect(service.parameters.keys).to contain_exactly(:tool_id)
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
    context 'when tool_id is missing' do
      it 'returns error message' do
        result = service.execute(tool_id: nil)
        expect(result).to eq('Tool ID is required')
      end

      it 'returns error for blank tool_id' do
        result = service.execute(tool_id: '')
        expect(result).to eq('Tool ID is required')
      end
    end

    context 'when tool is not found' do
      it 'returns not found message' do
        result = service.execute(tool_id: 999)
        expect(result).to include('not found')
      end
    end

    context 'when tool exists' do
      let!(:tool) { create(:captain_custom_tool, account: account, title: 'Tool To Delete') }

      it 'deletes the tool' do
        expect { service.execute(tool_id: tool.id) }.to change(Captain::CustomTool, :count).by(-1)
      end

      it 'returns success message with tool name' do
        result = service.execute(tool_id: tool.id)
        expect(result).to include('deleted successfully')
        expect(result).to include('Tool To Delete')
      end

      it 'returns success message with tool ID' do
        tool_id = tool.id
        result = service.execute(tool_id: tool_id)
        expect(result).to include(tool_id.to_s)
      end
    end

    context 'when tool belongs to different account' do
      let(:other_account) { create(:account) }
      let!(:other_tool) { create(:captain_custom_tool, account: other_account, title: 'Other Tool') }

      it 'returns not found' do
        result = service.execute(tool_id: other_tool.id)
        expect(result).to include('not found')
      end

      it 'does not delete the tool' do
        expect { service.execute(tool_id: other_tool.id) }.not_to change(Captain::CustomTool, :count)
      end
    end
  end
end
