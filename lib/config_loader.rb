class ConfigLoader
  DEFAULT_OPTIONS = {
    config_path: nil,
    reconcile_only_new: true
  }.freeze

  def process(options = {})
    options = DEFAULT_OPTIONS.merge(options)
    # function of the "reconcile_only_new" flag
    # if true,
    #   it leaves the existing config and feature flags as it is and
    #   creates the missing configs and feature flags with their default values
    # if false,
    #   then it overwrites existing config and feature flags with default values
    #   also creates the missing configs and feature flags with their default values
    @reconcile_only_new = options[:reconcile_only_new]

    # setting the config path
    @config_path = options[:config_path].presence
    @config_path ||= Rails.root.join('config')

    # general installation configs
    reconcile_general_config

    # default account based feature configs
    reconcile_feature_config
  end

  def general_configs
    @config_path ||= Rails.root.join('config')
    @general_configs ||= YAML.safe_load(File.read("#{@config_path}/installation_config.yml")).freeze
  end

  private

  def account_features
    @account_features ||= YAML.safe_load(File.read("#{@config_path}/features.yml")).freeze
  end

  def reconcile_general_config
    general_configs.each do |config|
      new_config = config.with_indifferent_access
      begin
        existing_config = InstallationConfig.find_by(name: new_config[:name])
        save_general_config(existing_config, new_config)
      rescue TypeError, Psych::DisallowedClass => e
        # Handle corrupted YAML data in database
        Rails.logger.warn("Error loading config #{new_config[:name]}: #{e.message}. Recreating...")
        InstallationConfig.where(name: new_config[:name]).destroy_all
        save_as_new_config(new_config)
      end
    end
  end

  def save_general_config(existing, latest)
    if existing
      # save config only if reconcile flag is false and existing configs value does not match default value
      save_as_new_config(latest) if !@reconcile_only_new && compare_values(existing, latest)
    else
      save_as_new_config(latest)
    end
  end

  def compare_values(existing, latest)
    begin
      existing.value != latest[:value] ||
        (!latest[:locked].nil? && existing.locked != latest[:locked])
    rescue TypeError, Psych::DisallowedClass => e
      # If we can't read the existing value, consider it different
      Rails.logger.warn("Error comparing config #{existing.name}: #{e.message}")
      true
    end
  end

  def save_as_new_config(latest)
    config = InstallationConfig.find_or_initialize_by(name: latest[:name])
    config.value = latest[:value]
    config.locked = latest[:locked]
    config.save!
  end

  def reconcile_feature_config
    begin
      config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')

      if config
        begin
          return false if config.value.to_s == account_features.to_s
          compare_and_save_feature(config)
        rescue TypeError, Psych::DisallowedClass => e
          # Handle corrupted YAML data
          Rails.logger.warn("Error loading ACCOUNT_LEVEL_FEATURE_DEFAULTS: #{e.message}. Recreating...")
          config.destroy
          save_as_new_config({ name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: account_features, locked: true })
        end
      else
        save_as_new_config({ name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: account_features, locked: true })
      end
    rescue => e
      Rails.logger.error("Error in reconcile_feature_config: #{e.message}")
      raise
    end
  end

  def compare_and_save_feature(config)
    begin
      existing_value = config.value
      features = if @reconcile_only_new
                   # leave the existing feature flag values as it is and add new feature flags with default values
                   (existing_value + account_features).uniq { |h| h['name'] }
                 else
                   # update the existing feature flag values with default values and add new feature flags with default values
                   (account_features + existing_value).uniq { |h| h['name'] }
                 end
      config.update({ name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: features, locked: true })
    rescue TypeError, Psych::DisallowedClass => e
      # Handle corrupted YAML data
      Rails.logger.warn("Error reading feature config: #{e.message}. Recreating...")
      config.destroy
      save_as_new_config({ name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: account_features, locked: true })
    end
  end
end
