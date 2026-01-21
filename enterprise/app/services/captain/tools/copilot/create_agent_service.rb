class Captain::Tools::Copilot::CreateAgentService < Captain::Tools::BaseTool
  def self.name
    'create_agent'
  end

  description <<~DESC
    Invite a new agent to the account. An invitation email will be sent to the provided email address.

    **Parameters:**
    - email: Required. Email address of the agent to invite.
    - name: Optional. Name of the agent (defaults to email prefix if not provided).
    - role: Optional. Role of the agent: 'agent' or 'administrator' (default: 'agent').

    **Note:** The invited user will receive an email to set up their password and access the account.
  DESC

  param :email, type: :string, desc: 'Email address of the agent to invite'
  param :name, type: :string, desc: 'Name of the agent', required: false
  param :role, type: :string, desc: 'Role: "agent" or "administrator" (default: agent)', required: false

  def execute(email:, name: nil, role: nil)
    return 'Email is required' if email.blank?

    email = email.strip.downcase
    role = validate_role(role)

    return 'Invalid role. Must be "agent" or "administrator"' unless role

    # Check if agent already exists in this account
    existing_user = @assistant.account.users.find_by(email: email)
    if existing_user.present?
      return {
        'content' => "An agent with email '#{email}' already exists in this account.",
        'entities' => [format_agent_entity(existing_user)]
      }
    end

    # Check account agent limit
    return 'Account agent limit exceeded. Please purchase more licenses.' unless can_add_agent?

    agent_name = name.presence || email.split('@').first

    builder = AgentBuilder.new(
      email: email,
      name: agent_name,
      role: role,
      availability: :offline,
      auto_offline: true,
      inviter: @user,
      account: @assistant.account
    )

    agent = builder.perform

    {
      'content' => "Agent '#{agent.name}' invited successfully. An invitation email has been sent to #{email}.",
      'entities' => [format_agent_entity(agent)]
    }
  rescue ActiveRecord::RecordInvalid => e
    "Failed to invite agent: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def validate_role(role)
    return :agent if role.blank?

    role = role.to_s.downcase.strip
    return :agent if role == 'agent'
    return :administrator if %w[administrator admin].include?(role)

    nil
  end

  def can_add_agent?
    current_count = @assistant.account.users.count
    limit = @assistant.account.usage_limits[:agents]
    limit.nil? || current_count < limit
  end

  def format_agent_entity(agent)
    account_user = agent.account_users.find { |au| au.account_id == @assistant.account.id }
    {
      'type' => 'agent',
      'id' => agent.id,
      'name' => agent.available_name || agent.name,
      'email' => agent.email,
      'role' => account_user&.role,
      'availability' => account_user&.availability
    }
  end
end
