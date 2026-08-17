class Api::V1::AccountsController < Api::V1::BaseController
  before_action :require_owner, only: [:update]

  def show
    render json: AccountSerializer.new(current_account).as_json
  end

  def update
    if current_account.update(account_params)
      render json: AccountSerializer.new(current_account).as_json
    else
      render_validation_errors(current_account)
    end
  end

  private

  def account_params
    params.require(:account).permit(:business_name, :timezone)
  end
end
