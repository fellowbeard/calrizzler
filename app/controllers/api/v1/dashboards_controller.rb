class Api::V1::DashboardsController < Api::V1::BaseController
  def show
    render json: dashboard_json
  end

  private

  def dashboard_json
    {
      user: user_json(current_user),
      appointments_count: user_appointments_scope.count,
      account: AccountSerializer.new(current_account).as_json,
      services: serialized_services,
      resources: serialized_resources,
      clients: serialized_clients,
      recent_clients: serialized_recent_clients,
      appointments: serialized_calendar_appointments,
      recent_appointments: serialized_recent_appointments,
    }
  end

  def clients_scope
    current_user.clients
  end

  def user_appointments_scope
    current_user.appointments.includes(:client, :services, :resource)
  end

  def calendar_appointments_scope
    current_account.appointments.includes(:user, :client, :services, :resource)
  end

  def services_scope
    current_user.services.alphabetical
  end

  def resources_scope
    current_account.resources.order(:name)
  end

  def serialized_services
    services_scope.map do |service|
      ServiceSerializer.new(service).as_json
    end
  end

  def serialized_resources
    resources_scope.map do |resource|
      resource.as_json(only: [:id, :name])
    end
  end

  def serialized_clients
    clients_scope
      .order(:last_name, :first_name)
      .map { |client| ClientSerializer.new(client).as_json }
  end

  def serialized_recent_clients
    clients_scope
      .order(created_at: :desc)
      .limit(5)
      .map { |client| ClientSerializer.new(client).as_json }
  end

  def serialized_calendar_appointments
    calendar_appointments_scope
      .order(:scheduled_at)
      .map { |appointment| calendar_appointment_json(appointment) }
  end

  def serialized_recent_appointments
    user_appointments_scope
      .order(scheduled_at: :desc)
      .limit(5)
      .map { |appointment| recent_appointment_json(appointment) }
  end

  def calendar_appointment_json(appointment)
    return AppointmentSerializer.new(appointment).as_json if appointment.user_id == current_user.id

    shared_appointment_json(appointment)
  end

  def shared_appointment_json(appointment)
    {
      id: appointment.id,
      user_id: appointment.user_id,
      user: user_name_json(appointment.user),
      resource_id: appointment.resource_id,
      resource: resource_json(appointment.resource),
      scheduled_at: appointment.scheduled_at,
      duration_minutes: appointment.duration_minutes,
      status: appointment.status,
    }
  end

  def resource_json(resource)
    return unless resource

    {
      id: resource.id,
      name: resource.name,
    }
  end

  def user_name_json(user)
    {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
    }
  end

  def recent_appointment_json(appointment)
    {
      id: appointment.id,
      client_id: appointment.client_id,
      scheduled_at: appointment.convert_time,
    }
  end

  def user_json(user)
    user.as_json(
      only: [:id, :account_id, :role, :first_name, :last_name, :email]
    )
  end
end
