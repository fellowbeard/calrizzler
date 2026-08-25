class UserInvitationMailer < ApplicationMailer
  def invite
    @invitation = params[:invitation]
    @token = params[:token]

    @accept_url = "#{frontend_url}/accept-invitation?token=#{CGI.escape(@token)}"

    mail(
      to: @invitation.email,
      subject: "You're invited to join #{@invitation.account.business_name}"
    )
  end

  private

  def frontend_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
  end
end
