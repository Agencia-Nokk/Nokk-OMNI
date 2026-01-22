module Enterprise::SuperAdmin::AccountsController
  def create
    @manually_managed_features_params = params[:account]&.delete(:manually_managed_features)
    super
  end

  def update
    if params[:account] && params[:account][:manually_managed_features].present?
      service = ::Internal::Accounts::InternalAttributesService.new(requested_resource)
      service.manually_managed_features = params[:account][:manually_managed_features]
      params[:account].delete(:manually_managed_features)
    end
    super
  end

  private

  def after_create_action
    if @manually_managed_features_params.present? && requested_resource.persisted?
      service = ::Internal::Accounts::InternalAttributesService.new(requested_resource)
      service.manually_managed_features = @manually_managed_features_params
    end
  end
end