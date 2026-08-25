class Api::V1::UserInvitationsController < Api::V1::BaseController
  skip_before_action :require_current_user, only: :accept
  before_action :require_owner, only: [:index, :create]

  def index
    invitations = current_account.user_invitations.order(created_at: :desc)

    render json: invitations
  end

  def create
    token_data = SecureToken.generate

    invitation = UserInvitation.new(
      account: current_account,
      invited_by: current_user,
      email: invitation_params[:email],
      role: invitation_params[:role],
      token_digest: token_data[:digest],
      expires_at: 2.days.from_now
    )

    if invitation.save
      UserInvitationMailer
        .with(invitation: invitation, token: token_data[:token])
        .invite
        .deliver_now

      render json: invitation, status: :created
    else
      render_validation_errors(invitation)
    end
  end

  def accept
    invitation = find_invitation

    return render_invalid_invitation unless invitation
    return render_unusable_invitation unless invitation.usable?

    user = accept_invitation(invitation)

    render json: user, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_validation_errors(e.record)
  end

  private

  def find_invitation
    token = params.require(:token)

    UserInvitation.find_by(
      token_digest: SecureToken.digest(token)
    )
  end

  def accept_invitation(invitation)
    user = nil

    User.transaction do
      user = User.create!(
        account: invitation.account,
        first_name: accept_params[:first_name],
        last_name: accept_params[:last_name],
        email: accept_params[:email],
        role: invitation.role,
        password: accept_params[:password],
        password_confirmation: accept_params[:password_confirmation]
      )

      invitation.update!(accepted_at: Time.current)
    end

    user
  end

  def render_invalid_invitation
    render_error(
      code: 'invalid_invitation',
      message: 'Invitation is invalid.',
      status: :unprocessable_entity
    )
  end

  def render_unusable_invitation
    render_error(
      code: 'invalid_invitation',
      message: 'Invitation has expired or has already been accepted.',
      status: :unprocessable_entity
    )
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end

  def accept_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation
    )
  end
end
