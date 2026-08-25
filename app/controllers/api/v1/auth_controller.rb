class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :require_current_user, only: [:login]

  def login
    user = User.find_by(email: params[:email]&.strip&.downcase)

    if user&.authenticate(params[:password])
      token = JwtService.encode(user_id: user.id)

      render json: {
        token: token,
        user: user.as_json(
          only: [:id, :account_id, :role, :first_name, :last_name, :email]
        ),
      }
    else
      render_error(
        code: 'invalid_credentials',
        message: 'Invalid email or password.',
        status: :unauthorized
      )
    end
  end
end
