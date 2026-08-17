class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :update_role, :destroy]
  before_action :require_write_access, only: [:update]
  before_action :require_owner, only: [:create, :update_role, :destroy]
  before_action :require_self_or_owner, only: [:update]

  def index
    render json: current_account.users.map { |user| user_json(user) }
  end

  def show
    render json: user_json(@user)
  end

  def create
    user = current_account.users.new(user_params)
    user.role = requested_role

    if user.save
      render json: user_json(user), status: :created
    else
      render_validation_errors(user)
    end
  end

  def update
    if @user.update(user_params)
      render json: user_json(@user)
    else
      render_validation_errors(@user)
    end
  end

  def update_role
    @user.role = requested_role

    if @user.save
      render json: user_json(@user)
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

  def require_self_or_owner
    return if current_user.owner?
    return if current_user.id == @user.id

    render_error(
      code: 'forbidden',
      message: 'You can only update your own profile.',
      status: :forbidden
    )
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation
    )
  end

  def requested_role
    role = params.require(:user).require(:role)

    return role if User.roles.key?(role)

    raise ActionController::BadRequest, 'Invalid user role.'
  end
end
