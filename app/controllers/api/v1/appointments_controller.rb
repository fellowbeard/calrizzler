class Api::V1::AppointmentsController < Api::V1::BaseController
  before_action :require_write_access, only: [:create, :update, :destroy]
  before_action :set_appointment, only: [:show, :update, :destroy]

  def index
    appointments = current_user
                   .appointments
                   .includes(:client, :resource, :services)

    render json: appointments.map { |appointment|
      AppointmentSerializer.new(appointment).as_json
    }
  end

  def show
    render json: AppointmentSerializer.new(@appointment).as_json
  end

  def create
    appointment = build_appointment

    if appointment.save
      render json: AppointmentSerializer.new(appointment).as_json,
             status: :created
    else
      render_validation_errors(appointment)
    end
  end

  def update
    Appointment.transaction do
      @appointment.assign_attributes(appointment_attributes)
      assign_update_associations
      @appointment.save!
    end

    render json: AppointmentSerializer.new(@appointment).as_json
  rescue ActiveRecord::RecordInvalid
    render_validation_errors(@appointment)
  end

  def destroy
    @appointment.destroy
    head :no_content
  end

  def calendar
    appointments = current_account
                   .appointments
                   .includes(:user, :resource)
                   .order(:scheduled_at)

    render json: appointments.map { |appointment| calendar_json(appointment) }
  end

  private

  def set_appointment
    @appointment = current_user.appointments.find(params[:id])
  end

  def build_appointment
    appointment = current_user.appointments.new(appointment_attributes)

    appointment.account = current_account
    appointment.client = find_user_client
    appointment.resource = find_account_resource if appointment_params[:resource_id].present?
    appointment.services = find_user_services

    appointment
  end

  def assign_update_associations
    @appointment.client = find_user_client if appointment_params[:client_id].present?

    @appointment.resource = find_account_resource if appointment_params[:resource_id].present?

    return unless appointment_params.key?(:service_ids)

    @appointment.services = find_user_services
  end

  def appointment_attributes
    appointment_params
      .except(:service_ids, :scheduled_at)
      .merge(scheduled_at: parsed_scheduled_at)
  end

  def parsed_scheduled_at
    return nil if appointment_params[:scheduled_at].blank?

    Time.find_zone!(current_account.timezone).parse(
      appointment_params[:scheduled_at]
    )
  end

  def find_user_client
    current_user.clients.find(appointment_params[:client_id])
  end

  def find_account_resource
    current_account.resources.find(appointment_params[:resource_id])
  end

  def find_user_services
    service_ids = appointment_params[:service_ids] || []

    current_user.services.where(id: service_ids)
  end

  def appointment_params
    params.require(:appointment).permit(
      :client_id,
      :resource_id,
      :scheduled_at,
      :status,
      :duration_minutes,
      :duration_overridden,
      service_ids: []
    )
  end

  def calendar_json(appointment)
    {
      id: appointment.id,
      user_id: appointment.user_id,
      user_name: "#{appointment.user.first_name} #{appointment.user.last_name}",
      resource_id: appointment.resource_id,
      resource_name: appointment.resource&.name,
      scheduled_at: appointment.scheduled_at,
      duration_minutes: appointment.duration_minutes,
    }
  end
end
