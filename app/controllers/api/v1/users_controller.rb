class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :destroy]
  before_action :require_write_access, only: [:create, :update, :destroy]

  def index
    render json: current_account.users
  end

  def show
    render json: user_json(@user)
  end

  def create
    user = current_account.users.new(user_params)

    if user.save
      render json: user, status: :created
    else
      render_validation_errors(user)
    end
  end

  def update
    if @user.update(user_params)
      render json: @user
    else
      render_validation_errors(@user)
    end
  end

  def destroy
    @user.destroy!
    head :no_content
  end

  def me
    render json: user_json(current_user)
  end

  private

  def user_json(user)
    user.as_json(
      only: [:id, :account_id, :role, :first_name, :last_name, :email]
    )
  end

  def set_user
    @user = current_account.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :role,
      :password,
      :password_confirmation
    )
  end
end