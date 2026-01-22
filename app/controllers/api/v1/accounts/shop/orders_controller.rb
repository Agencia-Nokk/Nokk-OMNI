class Api::V1::Accounts::Shop::OrdersController < Api::V1::Accounts::BaseController
  before_action :set_order, only: [:show, :update, :confirm, :cancel]

  def index
    @orders = Current.account.shop_orders.includes(:contact, :items, :conversation).recent
    @orders = @orders.by_status(params[:status]) if params[:status].present?
  end

  def show; end

  def update
    if @order.update(order_params)
      render :show
    else
      render json: { errors: @order.errors }, status: :unprocessable_content
    end
  end

  def confirm
    @order.confirm!
    render :show
  end

  def cancel
    @order.cancel!
    render :show
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def set_order
    @order = Current.account.shop_orders.includes(:contact, :items).find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status, :internal_notes, :customer_notes)
  end
end
