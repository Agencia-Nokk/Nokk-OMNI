class Webhooks::UazapiController < ActionController::API
  def verify
    render plain: params[:challenge] || 'OK'
  end

  def process_payload
    Webhooks::UazapiEventsJob.perform_later(params.permit!.to_h, params[:phone_number])
    head :ok
  end
end
