class Api::V1::AppointmentsController < Api::V1::BaseController
  before_action :require_write_access, only: [:create, :update, :destroy]
  before_action :set_appointment, only: [:show, :update, :destroy]

  def index
    appointments = current_account.appointments.includes(:client, :resource, :services)

    render json: appointments.map { |appointment| AppointmentSerializer.new(appointment).as_json }
  end

  def show
    render json: AppointmentSerializer.new(@appointment).as_json
  end

  def create
    appointment = build_appointment

    if appointment.save
      render json: AppointmentSerializer.new(appointment).as_json, status: :created
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

  private

  def set_appointment
    @appointment = current_account.appointments.find(params[:id])
  end

  def build_appointment
    appointment = current_account.appointments.new(appointment_attributes)
    appointment.user = current_user
    appointment.client = find_account_client
    appointment.resource = find_account_resource if appointment_params[:resource_id].present?
    appointment.services = find_account_services
    appointment
  end

  def assign_update_associations
    @appointment.client = find_account_client if appointment_params[:client_id].present?
    @appointment.resource = find_account_resource if appointment_params[:resource_id].present?
    @appointment.services = find_account_services if appointment_params.key?(:service_ids)
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

  def find_account_client
    current_account.clients.find(appointment_params[:client_id])
  end

  def find_account_resource
    current_account.resources.find(appointment_params[:resource_id])
  end

  def find_account_services
    service_ids = appointment_params[:service_ids] || []
    current_account.services.where(id: service_ids)
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
end
