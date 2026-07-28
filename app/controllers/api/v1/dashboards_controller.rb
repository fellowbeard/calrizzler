class Api::V1::DashboardsController < Api::V1::BaseController
  def show
    render json: dashboard_json
  end

  private

  def dashboard_json
    {
      user: user_json(current_user),
      appointments_count: current_account.appointments.count,
      account: AccountSerializer.new(current_account).as_json,
      services: serialized_services,
      resources: serialized_resources,
      clients: serialized_clients,
      recent_clients: serialized_recent_clients,
      appointments: serialized_appointments,
      recent_appointments: serialized_recent_appointments,
    }
  end

  def clients_scope
    current_account.clients
  end

  def appointments_scope
    current_account.appointments.includes(:client, :services, :resource)
  end

  def services_scope
    current_account.services.alphabetical
  end

  def resources_scope
    current_account.resources.order(:name)
  end

  def serialized_services
    services_scope.map { |service| ServiceSerializer.new(service).as_json }
  end

  def serialized_resources
    resources_scope.map { |resource| resource.as_json(only: [:id, :name]) }
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

  def serialized_appointments
    appointments_scope
      .order(:scheduled_at)
      .map { |appointment| AppointmentSerializer.new(appointment).as_json }
  end

  def serialized_recent_appointments
    appointments_scope
      .order(scheduled_at: :desc)
      .limit(5)
      .map { |appointment| recent_appointment_json(appointment) }
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