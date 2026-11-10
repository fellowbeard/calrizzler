class Api::V1::SearchController < Api::V1::BaseController
  RESULT_LIMIT = 20
  VALID_STATUSES = ['scheduled', 'completed', 'canceled'].freeze

  def index
    return render json: empty_results if search_params_blank?
    return render_search_error('Invalid appointment status.') if invalid_status?
    return render_search_error('Invalid appointment date. Use YYYY-MM-DD.') if invalid_date?

    render json: search_results(search_query, search_date, search_status)
  end

  private

  def search_query
    params[:q].to_s.strip
  end

  def search_date
    params[:date].to_s.strip
  end

  def search_status
    params[:status].to_s.strip
  end

  def search_params_blank?
    search_query.blank? && search_date.blank? && search_status.blank?
  end

  def invalid_status?
    search_status.present? && !VALID_STATUSES.include?(search_status)
  end

  def invalid_date?
    search_date.present? && !valid_date?(search_date)
  end

  def valid_date?(date)
    return false unless date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.iso8601(date)
    true
  rescue Date::Error
    false
  end

  def empty_results
    {
      clients: [],
      appointments: [],
      services: [],
    }
  end

  def render_search_error(message)
    render json: {
      error: {
        code: 'bad_request',
        message: message,
        details: nil,
      },
    }, status: :bad_request
  end

  def search_results(query, date, status)
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    filtering_appointments = date.present? || status.present?

    {
      clients: query.present? && !filtering_appointments ? search_clients(pattern) : [],
      appointments: search_appointments(query.present? ? pattern : nil, date, status),
      services: query.present? && !filtering_appointments ? search_services(pattern) : [],
    }
  end

  def search_clients(pattern)
    current_user.clients
                .where(
                  "first_name ILIKE :q OR
                   last_name ILIKE :q OR
                   CONCAT_WS(' ', first_name, last_name) ILIKE :q OR
                   email ILIKE :q OR
                   phone ILIKE :q",
                  q: pattern
                )
                .order(:last_name, :first_name, :id)
                .limit(RESULT_LIMIT)
                .map { |client| ClientSerializer.new(client).as_json }
  end

  def search_appointments(pattern, date, status)
    filtered_appointments(pattern, date, status)
      .order(:scheduled_at, :id)
      .limit(RESULT_LIMIT)
      .map { |appointment| AppointmentSerializer.new(appointment).as_json }
  end

  def filtered_appointments(pattern, date, status)
    appointments = current_user.appointments
                               .includes(:client, :resource, appointment_services: :service)

    appointments = match_appointment_text(appointments, pattern) if pattern.present?
    appointments = appointments.where(status: status) if status.present?
    appointments = filter_appointment_date(appointments, date) if date.present?

    appointments
  end

  def match_appointment_text(appointments, pattern)
    appointments
      .left_joins(:client, :services)
      .where(
        "clients.first_name ILIKE :q OR
         clients.last_name ILIKE :q OR
         CONCAT_WS(' ', clients.first_name, clients.last_name) ILIKE :q OR
         services.title ILIKE :q",
        q: pattern
      )
      .distinct
  end

  def filter_appointment_date(appointments, date)
    timezone = Time.find_zone!(current_account.timezone)
    start_time = timezone.parse(date).beginning_of_day

    appointments.where(scheduled_at: start_time...start_time.next_day)
  end

  def search_services(pattern)
    current_account.services
                   .active
                   .where('title ILIKE ?', pattern)
                   .alphabetical
                   .limit(RESULT_LIMIT)
                   .map { |service| ServiceSerializer.new(service).as_json }
  end
end
