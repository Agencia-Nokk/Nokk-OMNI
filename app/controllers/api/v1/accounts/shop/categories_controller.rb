class Api::V1::Accounts::Shop::CategoriesController < Api::V1::Accounts::BaseController
  before_action :set_category, only: [:show, :update, :destroy]

  def index
    @categories = Current.account.shop_categories.ordered
    @categories = @categories.active if params[:active_only]
  end

  def show; end

  def create
    @category = Current.account.shop_categories.new(category_params)

    if @category.save
      render :show, status: :created
    else
      render json: { errors: @category.errors }, status: :unprocessable_content
    end
  end

  def update
    if @category.update(category_params)
      render :show
    else
      render json: { errors: @category.errors }, status: :unprocessable_content
    end
  end

  def destroy
    @category.destroy!
    head :no_content
  end

  private

  def set_category
    @category = Current.account.shop_categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :slug, :description, :position, :active, :image)
  end
end
