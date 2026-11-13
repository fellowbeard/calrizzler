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

  # PUT /api/v1/working_hours/replace
  # Swaps the whole weekly schedule in one transaction, so a bad range
  # leaves the existing hours untouched instead of half-saved.
  def replace
    WorkingHour.transaction do
      current_account.working_hours.destroy_all
      replacement_params.each { |attributes| current_account.working_hours.create!(attributes) }
    end

    render json: current_account.working_hours.order(:day_of_week, :opens_at)
  rescue ActiveRecord::RecordInvalid => e
    render_validation_errors(e.record)
  end

  private

  def replacement_params
    raise ActionController::ParameterMissing, :working_hours unless params.key?(:working_hours)

    params.permit(working_hours: [:day_of_week, :opens_at, :closes_at]).fetch(:working_hours, [])
  end

  def set_working_hour
    @working_hour = current_account.working_hours.find(params[:id])
  end

  def working_hour_params
    params.require(:working_hour).permit(:day_of_week, :opens_at, :closes_at)
  end
end
