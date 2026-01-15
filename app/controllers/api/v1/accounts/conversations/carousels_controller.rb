class Api::V1::Accounts::Conversations::CarouselsController < Api::V1::Accounts::Conversations::BaseController
  def create
    result = Uazapi::SendCarouselService.new(
      conversation: @conversation,
      product_ids: carousel_params[:product_ids],
      text: carousel_params[:text]
    ).perform

    if result[:success]
      render json: { success: true, message: result[:message] }, status: :created
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def carousel_params
    params.permit(:text, product_ids: [])
  end
end
