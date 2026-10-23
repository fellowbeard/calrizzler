class Api::V1::WorkingHoursController < Api::V1::BaseController
  before_action :require_owner, except: [:index]
  before_action :set_working_hour, only: [:update, :destroy]

  def index
    working_hours = current_account.working_hours.order(:day_of_week, :opens_at)
    render json: working_hours
  end

  def create
    working_hour = current_account.working_hours.build(working_hour_params)

    if working_hour.save
      render json: working_hour, status: :created
    else
      render_validation_errors(working_hour)
    end
  end

  def update
    if @working_hour.update(working_hour_params)
      render json: @working_hour
    else
      render_validation_errors(@working_hour)
    end
  end

  def destroy
    @working_hour.destroy!
    head :no_content
  end

  private

  def set_working_hour
    @working_hour = current_account.working_hours.find(params[:id])
  end

  def working_hour_params
    params.require(:working_hour).permit(:day_of_week, :opens_at, :closes_at)
  end
end
