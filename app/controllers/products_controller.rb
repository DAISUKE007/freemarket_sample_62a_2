class ProductsController < ApplicationController
  before_action :set_card, only:[:buy,:purchase]

  # 商品一覧 -----------------------------------
  def index
    @products = Product.order("created_at DESC")
  end

  # 商品出品 ------------------------------------
  def new
    @product = Product.new
    @product.images.build
  end

  # 子カテゴリー ----------------------------------
  def category_children
    @category_children = Category.find_by(name: "#{params[:parent_name]}", ancestry: nil).children
  end

  # 孫カテゴリー ----------------------------------
  def category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  # 商品出品の保存 -------------------------------
  def create
    @product= Product.new(
      category_id: params[:category_id].to_i,
      name: product_params[:name],
      description: product_params[:description],
      condition: product_params[:condition],
      shipping_charge: product_params[:shipping_charge],
      shipping_area: product_params[:shipping_area],
      shipping_date: product_params[:shipping_date],
      shipping_method: product_params[:shipping_method],
      price: product_params[:price],
      seller_id: current_user.id
    )
    if @product.save
      params[:images][:image].each do |image|
        @product.images.create(image: image, product_id: @product.id)
      end
      redirect_to root_path
    else
      @product.images.build
      render action: 'new'
    end
  end

  # 出品商品の編集 -------------------------------
  def edit
    @product = Product.find(params[:id])
  end

  # 出品商品の更新 -------------------------------
  def update
    product = Product.find(params[:id])
    product.update(
      category_id: params[:category_id].to_i,
      name: product_params[:name],
      description: product_params[:description],
      condition: product_params[:condition],
      shipping_charge: product_params[:shipping_charge],
      shipping_area: product_params[:shipping_area],
      shipping_date: product_params[:shipping_date],
      shipping_method: product_params[:shipping_method],
      price: product_params[:price],
      seller_id: current_user.id
    )
    product.images.update(
      image: product_params[:images_attributes]["0"]["image"]
    )
    redirect_to root_path
  end

  # 商品詳細 ------------------------------------
  def show
    @images = Image.includes(:product).order('id desc')
    @product = Product.find(params[:id])
    @seller = User.find(@product.seller_id)
  end

  
  require 'payjp'

  # 商品の購入 ----------------------------------
  def buy
    @images = Image.includes(:product)
    @product = Product.find(params[:id])
    
    if @creditcard.blank?
      redirect_to controller: "cards", action: "new"                              #登録された情報がない場合にカード登録画面に移動
    else
      Payjp.api_key = "sk_test_96c344952e792691d9fc840e"
      customer = Payjp::Customer.retrieve(@creditcard.customer_id)                #保管した顧客IDでpayjpから情報取得
      @default_card_information = customer.cards.retrieve(@creditcard.card_id)    #カード情報表示のためインスタンス変数に代入
    end
  end

  # Pay.jp側に購入者情報を送信 ---------------------
  def purchase
    @product = Product.find(params[:id])
    @product.update(buyer_id: current_user.id)     #productテーブルにbuyer_idを入れる

    card_token = @creditcard.customer_id if @creditcard.present?
    Payjp.api_key = "sk_test_96c344952e792691d9fc840e"
    Payjp::Charge.create(
      amount: @product.price,
      customer: card_token,
      currency: 'jpy'
    )
    redirect_to action: 'complete'
  end

  # 購入完了画面 ---------------------------------
  def complete
  end
  
  # 商品の削除 -----------------------------------
  def destroy
    @product = Product.find(params[:id])
    if user_signed_in? && @product.seller_id == current_user.id
      @product.destroy
      redirect_to root_path
    else
      render acction: :show
    end
  end

  private

  # 入力された商品情報を取得 ------------------------
  def product_params
    params.require(:product).permit(
      :name, 
      :description,
      :condition, 
      :shipping_charge,
      :shipping_area,
      :shipping_date,
      :shipping_method,
      :category_id,
      :buyer_id,
      :size_id,
      :brand_id,
      :price,
      images_attributes: [:image,:product_id]).merge(seller_id: current_user.id)
  end

  # ログインユーザーのクレジット情報
  #（顧客id と カードID)を取得 -----------------------
  def set_card
    if user_signed_in?
      @creditcard = CreditCard.where(user_id: current_user.id).first if CreditCard.where(user_id: current_user.id).present?
    else
      @creditcard = 'nill'
    end
  end

end