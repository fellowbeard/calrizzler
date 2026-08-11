class Api::V1::BaseController < ActionController::API
  before_action :require_current_user

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def current_user
    return @current_user if defined?(@current_user)

    header = request.headers['Authorization']
    token = header&.split(' ')&.last
    payload = JwtService.decode(token)

    @current_user = User.find_by(id: payload['user_id']) if payload
  end

  def require_current_user
    return if current_user

    render_error(
      code: 'unauthorized',
      message: 'You must be logged in to do that.',
      status: :unauthorized
    )
  end

  def current_account
    current_user.account
  end

  def require_write_access
    return if current_user.can_write?

    render_error(
      code: 'forbidden',
      message: 'Read-only users cannot make changes.',
      status: :forbidden
    )
  end

  def require_owner
    return if current_user.owner?

    render_error(
      code: 'forbidden',
      message: 'Only account owners can do that.',
      status: :forbidden
    )
  end

  def render_validation_errors(record)
    render_error(
      code: 'validation_failed',
      message: 'Validation failed.',
      status: :unprocessable_entity,
      details: record.errors.to_hash(true)
    )
  end

  def render_not_found(exception)
    render_error(
      code: 'not_found',
      message: exception.message,
      status: :not_found
    )
  end

  def render_bad_request(exception)
    render_error(
      code: 'bad_request',
      message: exception.message,
      status: :bad_request
    )
  end

  def render_error(code:, message:, status:, details: nil)
    render json: {
      error: {
        code: code,
        message: message,
        details: details,
      },
    }, status: status
  end
end
