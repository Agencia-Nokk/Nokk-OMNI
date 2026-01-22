class Api::V1::Accounts::Shop::CartsController < Api::V1::Accounts::BaseController
  before_action :set_cart, only: [:show, :destroy, :add_item, :remove_item, :update_item, :convert_to_order]
  before_action :set_conversation, only: [:create, :show_by_conversation]

  def index
    @carts = Current.account.shop_carts.includes(:items, :contact, :conversation).active.order(updated_at: :desc)
  end

  def show; end

  def show_by_conversation
    @cart = Current.account.shop_carts.find_or_create_by!(
      conversation: @conversation,
      contact: @conversation.contact
    )
    render :show
  end

  def create
    @cart = Current.account.shop_carts.new(cart_params)
    @cart.conversation = @conversation if @conversation

    if @cart.save
      render :show, status: :created
    else
      render json: { errors: @cart.errors }, status: :unprocessable_content
    end
  end

  def add_item
    product = Current.account.shop_products.find(params[:product_id])
    variant = product.variants.find(params[:variant_id]) if params[:variant_id].present?
    quantity = params[:quantity]&.to_i || 1

    @item = @cart.add_item(product, quantity: quantity, variant: variant)
    render json: { cart: cart_json, item: item_json(@item) }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors }, status: :unprocessable_content
  end

  def remove_item
    @cart.remove_item(params[:item_id])
    render json: { cart: cart_json }
  end

  def update_item
    @cart.update_item_quantity(params[:item_id], params[:quantity].to_i)
    render json: { cart: cart_json }
  end

  def convert_to_order
    @order = @cart.convert_to_order!(
      user: Current.user,
      customer_notes: params[:customer_notes]
    )
    render json: { order: order_json(@order) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors }, status: :unprocessable_content
  end

  def destroy
    @cart.destroy!
    head :no_content
  end

  private

  def set_cart
    @cart = Current.account.shop_carts.includes(items: [:product, :variant]).find(params[:id])
  end

  def set_conversation
    @conversation = Current.account.conversations.find(params[:conversation_id]) if params[:conversation_id].present?
  end

  def cart_params
    params.require(:cart).permit(:contact_id, :conversation_id)
  end

  def cart_json
    {
      id: @cart.id,
      subtotal: @cart.subtotal,
      total_items: @cart.total_items,
      items: @cart.items.map { |item| item_json(item) }
    }
  end

  def item_json(item)
    {
      id: item.id,
      product_id: item.product.id,
      product_name: item.product.name,
      variant_id: item.variant&.id,
      variant_name: item.variant&.name,
      quantity: item.quantity,
      unit_price: item.unit_price,
      total_price: item.total_price
    }
  end

  def order_json(order)
    {
      id: order.id,
      order_number: order.order_number,
      status: order.status,
      total: order.total
    }
  end
end
