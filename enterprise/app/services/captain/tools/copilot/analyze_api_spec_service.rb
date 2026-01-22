# frozen_string_literal: true

class Captain::Tools::Copilot::AnalyzeApiSpecService < Captain::Tools::BaseTool
  def self.name
    'analyze_api_spec'
  end

  description <<~DESC
    Prepare API documentation for analysis and tool creation. This tool
    formats the documentation with guided instructions to help you
    extract the necessary information for creating a custom tool.

    **When to use:**
    - After reading API documentation with read_api_documentation
    - Before creating a custom tool to structure your analysis

    **What you should extract:**
    1. The base endpoint URL with Liquid template variables (e.g., {{ param_name }})
    2. HTTP method (GET or POST)
    3. Required and optional parameters with types
    4. Authentication requirements
    5. Response format for creating response_template
  DESC

  param :documentation, type: :string, desc: 'API documentation content (from read_api_documentation)'
  param :desired_functionality, type: :string, desc: 'What the user wants to do (e.g., "lookup CEP address")'

  def execute(documentation:, desired_functionality:)
    return 'Documentation content is required' if documentation.blank?
    return 'Desired functionality description is required' if desired_functionality.blank?

    {
      'content' => build_analysis_prompt(documentation, desired_functionality)
    }
  end

  def active?
    true
  end

  private

  def build_analysis_prompt(documentation, desired_functionality)
    <<~PROMPT
      ## API Analysis for: #{desired_functionality}

      #{documentation}

      ---

      ## Analysis Instructions

      Based on the documentation above, extract the following information to create a custom tool:

      ### 1. Endpoint URL
      - Identify the base URL and path
      - Replace dynamic values with Liquid template variables: `{{ variable_name }}`
      - Example: `https://api.example.com/users/{{ user_id }}/orders`

      ### 2. HTTP Method
      - Determine if it's GET (retrieving data) or POST (sending data)

      ### 3. Parameters (param_schema)
      For each parameter, identify:
      ```json
      [
        {
          "name": "parameter_name",
          "type": "string|number|boolean",
          "description": "What this parameter does",
          "required": true|false
        }
      ]
      ```

      ### 4. Authentication
      - **none**: No authentication required
      - **bearer**: Token in Authorization header
      - **basic**: Username/password
      - **api_key**: API key in header or query string

      ### 5. Response Template (optional)
      Format the response for the user. Use Liquid syntax:
      ```
      {{ response.field_name }}
      ```

      ---

      ## Next Step

      Once you have extracted this information, use `create_custom_tool` with:
      - `title`: A descriptive name for the tool
      - `description`: What the tool does (for LLM to understand when to use it)
      - `endpoint_url`: The URL with Liquid variables
      - `http_method`: GET or POST
      - `param_schema`: JSON array of parameters
      - `auth_type`: Authentication type
      - `auth_config`: Authentication configuration (if needed)
      - `response_template`: Template to format the response (optional)
    PROMPT
  end
end
