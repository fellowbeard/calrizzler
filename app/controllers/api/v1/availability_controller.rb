class Api::V1::AvailabilityController < Api::V1::BaseController
  def index
    date = Date.iso8601(params.require(:date))
    duration = Integer(params.require(:duration_minutes), 10)
    resource = current_account.resources.find(params.require(:resource_id))

    render json: {
      date: date.iso8601,
      timezone: current_account.timezone,
      slots: available_slots(date, duration, resource),
    }
  rescue ActionController::ParameterMissing, ArgumentError => e
    render json: {
      error: {
        code: 'invalid_availability_parameters',
        message: e.message,
      },
    }, status: :unprocessable_entity
  end

  private

  def available_slots(date, duration, resource)
    AvailabilityCalculator.new(
      user: current_user,
      date: date,
      duration_minutes: duration,
      resource: resource
    ).available_slots
  end
end
