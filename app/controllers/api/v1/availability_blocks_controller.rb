class Api::V1::AvailabilityBlocksController < Api::V1::BaseController
  before_action :require_write_access, except: [:index]
  before_action :set_user, only: [:index], unless: :account_block_request?
  before_action :set_user, only: [:create], unless: :account_block_request?
  before_action :set_availability_block, only: [:update, :destroy]

  def index
    blocks = if params[:scope] == 'account'
               current_account.availability_blocks.where(user_id: nil)
             else
               @user.availability_blocks
             end

    render json: blocks.order(:starts_at)
  end

  def create
    block = build_availability_block
    return unless block

    if block.save
      render json: block, status: :created
    else
      render_validation_errors(block)
    end
  end

  def update
    return unless require_block_access(@availability_block)

    if @availability_block.update(availability_block_params)
      render json: @availability_block
    else
      render_validation_errors(@availability_block)
    end
  end

  def destroy
    return unless require_block_access(@availability_block)

    @availability_block.destroy!
    head :no_content
  end

  private

  def set_user
    @user = current_account.users.find(params[:user_id] || current_user.id)
  end

  def set_availability_block
    @availability_block = AvailabilityBlock
                          .joins(:user)
                          .where(users: { account_id: current_account.id })
                          .find(params[:id])
  end

  def require_schedule_access(user)
    return true if current_user.owner?
    return true if current_user.id == user.id

    render_error(
      code: 'forbidden',
      message: "You cannot modify another provider's blocked time.",
      status: :forbidden
    )

    false
  end

  def availability_block_params
    params.require(:availability_block).permit(:starts_at, :ends_at)
  end

  def build_availability_block
    return build_account_block if account_block_request?

    build_provider_block
  end

  def account_block_request?
    params[:scope] == 'account' && params[:user_id].blank?
  end

  def build_account_block
    unless current_user.owner?
      render_error(
        code: 'forbidden',
        message: 'Only owners can manage business closures.',
        status: :forbidden
      )
      return nil
    end

    current_account.availability_blocks.build(availability_block_params)
  end

  def build_provider_block
    return nil unless require_schedule_access(@user)

    @user.availability_blocks.build(availability_block_params).tap do |block|
      block.account = current_account
    end
  end

  def require_block_access(block)
    if block.user.nil?
      return true if current_user.owner?

      render_error(
        code: 'forbidden',
        message: 'Only owners can manage business closures.',
        status: :forbidden
      )
      return false
    end

    require_schedule_access(block.user)
  end
end
