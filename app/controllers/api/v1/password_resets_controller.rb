class Api::V1::PasswordResetsController < Api::V1::BaseController
  skip_before_action :require_current_user, only: [:create, :confirm]

  RESET_EXPIRATION = 1.hour

  def create
    user = User.find_by(email: normalized_email)

    create_password_reset(user) if user

    render json: {
      message: 'If an account exists for that email, password reset instructions have been sent.',
    }, status: :ok
  end

  def confirm
    reset = find_password_reset

    return render_invalid_token unless reset&.usable?

    reset_password!(reset)

    render json: {
      message: 'Password has been reset successfully.',
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      errors: e.record.errors.full_messages,
    }, status: :unprocessable_entity
  end

  private

  def normalized_email
    params[:email].to_s.strip.downcase
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end

  def create_password_reset(user)
    token_data = SecureToken.generate

    reset = user.password_resets.create!(
      token_digest: token_data[:digest],
      expires_at: RESET_EXPIRATION.from_now
    )

    PasswordResetMailer.with(
      password_reset: reset,
      token: token_data[:token]
    ).reset_password.deliver_later
  end

  def find_password_reset
    PasswordReset.find_by(
      token_digest: SecureToken.digest(params[:token].to_s)
    )
  end

  def render_invalid_token
    render json: {
      error: 'Invalid or expired password reset token.',
    }, status: :unprocessable_entity
  end

  def reset_password!(reset)
    PasswordReset.transaction do
      reset.user.update!(password_params)

      reset.user.password_resets
          .where(used_at: nil)
          .update_all(used_at: Time.current)
    end
  end
end
