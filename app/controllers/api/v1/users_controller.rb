class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :update_role, :destroy, :activate]
  before_action :require_write_access, only: [:update]
  before_action :require_owner, only: [:create, :update_role, :destroy, :activate]
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
    attributes = user_params

    return unless valid_password_change?(attributes)

    if @user.update(attributes)
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
    return render_cannot_deactivate_self if @user == current_user

    @user.update!(active: false)
    head :no_content
  end

  def activate
  if @user.update(active: true)
    render json: user_json(@user)
  else
    render_validation_errors(@user)
  end
end

  def me
    render json: user_json(current_user)
  end

  private

  def user_json(user)
    user.as_json(
      only: [:id, :account_id, :role, :first_name, :last_name, :email, :phone, :bio, :active]
    ).merge(
      avatar_url: user.avatar.attached? ? url_for(user.avatar) : nil
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
      :phone,
      :bio,
      :password,
      :password_confirmation,
      :avatar
    )
  end

  def valid_password_change?(attributes)
    return true unless attributes.key?(:password) || attributes.key?(:password_confirmation)

    return false unless password_change_allowed?
    return false unless current_password_valid?
    return false unless new_password_valid?(attributes)

    true
  end

  def password_change_allowed?
    return true if @user == current_user

    render_error(
      code: 'forbidden',
      message: 'You can only change your own password.',
      status: :forbidden
    )
    false
  end

  def current_password_valid?
    return true if current_user.authenticate(params.dig(:user, :current_password))

    render_error(
      code: 'invalid_current_password',
      message: 'Current password is incorrect.',
      status: :unprocessable_entity
    )
    false
  end

  def new_password_valid?(attributes)
    if attributes[:password].blank?
      render_error(
        code: 'invalid_password',
        message: 'New password is required.',
        status: :unprocessable_entity
      )
      return false
    end

    return true if attributes[:password] == attributes[:password_confirmation]

    render_error(
      code: 'password_confirmation_mismatch',
      message: 'Password confirmation does not match.',
      status: :unprocessable_entity
    )
    false
  end

  def requested_role
    role = params.require(:user).require(:role)

    return role if User::ROLES.include?(role)

    raise ActionController::BadRequest, 'Invalid user role.'
  end

  def render_cannot_deactivate_self
    render_error(
      code: 'cannot_deactivate_self',
      message: 'You cannot deactivate your own account.',
      status: :unprocessable_entity
    )
  end
end
