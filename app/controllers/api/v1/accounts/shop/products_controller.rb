class Api::V1::Accounts::Shop::ProductsController < Api::V1::Accounts::BaseController
  before_action :set_product, only: [:show, :update, :destroy]

  def index
    @products = Current.account.shop_products.includes(:category, :variants)
    @products = @products.active if params[:active_only]
    @products = @products.in_stock if params[:in_stock_only]
    @products = @products.by_category(params[:category_id]) if params[:category_id].present?
    @products = @products.order(created_at: :desc)
  end

  def show; end

  def create
    @product = Current.account.shop_products.new(product_params)

    if @product.save
      render :show, status: :created
    else
      render json: { errors: @product.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      render :show
    else
      render json: { errors: @product.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy!
    head :no_content
  end

  private

  def set_product
    @product = Current.account.shop_products.includes(:category, :variants).find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name, :slug, :description, :price, :compare_at_price,
      :sku, :stock_quantity, :track_inventory, :active,
      :shop_category_id, images: [], metadata: {}
    )
  end
end
