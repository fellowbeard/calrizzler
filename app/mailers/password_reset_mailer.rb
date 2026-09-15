class PasswordResetMailer < ApplicationMailer
  def reset_password
    @password_reset = params[:password_reset]
    @token = params[:token]

    @reset_url = "#{frontend_url}/reset-password?token=#{CGI.escape(@token)}"

    mail(
      to: @password_reset.user.email,
      subject: 'Reset your password'
    )
  end

  private

  def frontend_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
  end
end
