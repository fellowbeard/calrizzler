class Api::V1::ServicesController < Api::V1::BaseController
  before_action :require_owner, only: [:create, :update, :destroy]
  before_action :set_service, only: [:show, :update, :destroy]

  def index
    services = current_account.services.alphabetical

    render json: services.map { |service| ServiceSerializer.new(service).as_json }
  end

  def show
    render json: ServiceSerializer.new(@service).as_json
  end

  def create
    service = current_account.services.new(service_params)

    if service.save
      render json: ServiceSerializer.new(service).as_json, status: :created
    else
      render_validation_errors(service, code: 'service_validation_failed')
    end
  end

  def update
    if @service.update(service_params)
      render json: ServiceSerializer.new(@service).as_json
    else
      render_validation_errors(@service, code: 'service_validation_failed')
    end
  end

  def destroy
    @service.destroy
    head :no_content
  end

  private

  def set_service
    @service = current_account.services.find(params[:id])
  end

  def service_params
    params.require(:service).permit(
      :title,
      :price,
      :duration_minutes,
      :description
    )
  end
end
