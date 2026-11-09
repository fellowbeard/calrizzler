class Api::V1::AvailabilityController < Api::V1::BaseController
  def index
    date = Date.iso8601(params.require(:date))
    duration = Integer(params.require(:duration_minutes), 10)
    resource = current_account.resources.find(params.require(:resource_id))

    calculator = availability_calculator(date, duration, resource)

    render json: availability_response(date, calculator)
  rescue ActionController::ParameterMissing, ArgumentError => e
    render json: {
      error: {
        code: 'invalid_availability_parameters',
        message: e.message,
      },
    }, status: :unprocessable_entity
  end

  private

  def availability_response(date, calculator)
    {
      date: date.iso8601,
      timezone: current_account.timezone,
      slots: calculator.available_slots,
      candidate_slots: calculator.candidate_slots,
    }
  end

  def availability_calculator(date, duration, resource)
    AvailabilityCalculator.new(
      user: current_user,
      date: date,
      duration_minutes: duration,
      resource: resource
    )
  end
end
