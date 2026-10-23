class Api::V1::UserWorkingHoursController < Api::V1::BaseController
  before_action :require_write_access, except: [:index]
  before_action :set_user, only: [:index, :create]
  before_action :set_user_working_hour, only: [:update, :destroy]

  def index
    working_hours = @user.user_working_hours.order(:day_of_week, :opens_at)

    render json: working_hours
  end

  def create
    return unless require_schedule_access(@user)

    working_hour = @user.user_working_hours.build(user_working_hour_params)

    if working_hour.save
      render json: working_hour, status: :created
    else
      render_validation_errors(working_hour)
    end
  end

  def update
    return unless require_schedule_access(@user_working_hour.user)

    if @user_working_hour.update(user_working_hour_params)
      render json: @user_working_hour
    else
      render_validation_errors(@user_working_hour)
    end
  end

  def destroy
    return unless require_schedule_access(@user_working_hour.user)

    @user_working_hour.destroy!
    head :no_content
  end

  private

  def set_user
    @user = current_account.users.find(params[:user_id] || current_user.id)
  end

  def set_user_working_hour
    @user_working_hour = UserWorkingHour
                         .joins(:user)
                         .where(users: { account_id: current_account.id })
                         .find(params[:id])
  end

  def require_schedule_access(user)
    return true if current_user.owner?
    return true if current_user.id == user.id

    render_error(
      code: 'forbidden',
      message: "You cannot modify another provider's schedule.",
      status: :forbidden
    )

    false
  end

  def user_working_hour_params
    params.require(:user_working_hour)
          .permit(:day_of_week, :opens_at, :closes_at, :is_closed)
  end
end
