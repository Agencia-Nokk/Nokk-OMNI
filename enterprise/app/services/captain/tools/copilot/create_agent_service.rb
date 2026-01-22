class Captain::Tools::Copilot::CreateAgentService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::AgentHelpers

  def self.name
    'create_agent'
  end

  description <<~DESC
    Invite a new agent to the account. An invitation email will be sent to the provided email address.

    **When to use:** Use this tool when you need to add new team members to the support system. For example: onboarding new hires, adding managers, or expanding the support team.

    **Complete Example:**
    To invite a new support agent:
    {
      "email": "john.doe@company.com",
      "name": "John Doe",
      "role": "agent"
    }

    **Roles:**
    - agent: Can handle conversations and manage contacts (default)
    - administrator: Full access including settings, reports, and team management

    **Common Use Cases:**
    1. New Support Agent: email="support@company.com", role="agent"
    2. Team Manager: email="manager@company.com", role="administrator"
    3. Quick Invite: email="user@company.com" (uses email prefix as name, role defaults to agent)

    **Note:** The invited user will receive an email to set up their password and access the account. They can start handling conversations immediately after setup.
  DESC

  param :email, type: :string, desc: 'Email address of the agent to invite'
  param :name, type: :string, desc: 'Name of the agent', required: false
  param :role, type: :string, desc: 'Role: "agent" or "administrator" (default: agent)', required: false

  def execute(email:, name: nil, role: nil)
    validation = validate_invite_params(email, role)
    return validation unless validation.is_a?(Array)

    email, validated_role = validation
    create_agent_invite(email, name, validated_role)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to invite agent: #{e.message}"
  end

  def active?
    user_has_permission('administrator')
  end

  private

  def validate_invite_params(email, role)
    return 'Email is required' if email.blank?

    email = email.strip.downcase
    validated_role = validate_role(role)
    return 'Invalid role. Must be "agent" or "administrator"' unless validated_role

    existing = check_existing_agent(email)
    return existing if existing.is_a?(Hash)
    return 'Account agent limit exceeded. Please purchase more licenses.' unless can_add_agent?

    [email, validated_role]
  end

  def check_existing_agent(email)
    existing_user = @assistant.account.users.from_email(email)
    return nil if existing_user.blank?

    {
      'content' => "An agent with email '#{email}' already exists in this account.",
      'entities' => [format_agent_entity(existing_user)]
    }
  end

  def create_agent_invite(email, name, role)
    agent_name = name.presence || email.split('@').first
    agent = build_agent(email, agent_name, role)

    {
      'content' => "Agent '#{agent.name}' invited successfully. An invitation email has been sent to #{email}.",
      'entities' => [format_agent_entity(agent)]
    }
  end

  def build_agent(email, agent_name, role)
    AgentBuilder.new(
      email: email,
      name: agent_name,
      role: role,
      availability: :offline,
      auto_offline: true,
      inviter: @user,
      account: @assistant.account
    ).perform
  end

  def can_add_agent?
    current_count = @assistant.account.users.count
    limit = @assistant.account.usage_limits[:agents]
    limit.nil? || current_count < limit
  end
end
