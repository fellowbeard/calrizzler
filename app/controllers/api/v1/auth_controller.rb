class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :require_current_user, only: [:login]

  def login
    user = find_user

    return render_invalid_credentials unless valid_credentials?(user)
    return render_account_deactivated unless user.active?

    token = JwtService.encode(user_id: user.id)

    render json: {
      token: token,
      user: user.as_json(
        only: [:id, :account_id, :role, :first_name, :last_name, :email]
      ),
    }
  end

  private

  def find_user
    User.find_by(email: params[:email]&.strip&.downcase)
  end

  def valid_credentials?(user)
    user&.authenticate(params[:password])
  end

  def render_invalid_credentials
    render_error(
      code: 'invalid_credentials',
      message: 'Invalid email or password.',
      status: :unauthorized
    )
  end

  def render_account_deactivated
    render_error(
      code: 'account_deactivated',
      message: 'Your account has been deactivated. Contact your account owner for access.',
      status: :forbidden
    )
  end
end
