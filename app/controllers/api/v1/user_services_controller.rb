class Api::V1::UserServicesController < Api::V1::BaseController
  before_action :require_write_access, except: [:index, :show]
  before_action :set_provider
  before_action :authorize_provider_management!, only: [:create, :update, :destroy]
  before_action :set_user_service, only: [:show, :update, :destroy]

  def index
    offerings = @provider.user_services.includes(:service).order(:id)

    render json: offerings.map { |offering| serialize_offering(offering) }
  end

  def show
    render json: serialize_offering(@user_service)
  end

  def create
    service = current_account.services.find(user_service_params[:service_id])

    offering = @provider.user_services.new(
      service: service,
      price: user_service_params[:price]
    )

    if offering.save
      render json: serialize_offering(offering), status: :created
    else
      render_validation_errors(offering, code: 'user_service_validation_failed')
    end
  end

  def update
    if @user_service.update(user_service_params.slice(:price))
      render json: serialize_offering(@user_service)
    else
      render_validation_errors(@user_service, code: 'user_service_validation_failed')
    end
  end

  def destroy
    @user_service.destroy!
    head :no_content
  end

  private

  def set_provider
    @provider = current_account.users.find(params[:user_id])
  end

  def authorize_provider_management!
    return if current_user.owner?
    return if current_user.staff? && current_user.id == @provider.id

    render_error(
      code: 'forbidden',
      message: 'You cannot manage this provider’s services.',
      status: :forbidden
    )
  end

  def set_user_service
    @user_service = @provider.user_services.find(params[:id])
  end

  def user_service_params
    params.require(:user_service).permit(:service_id, :price)
  end

  def serialize_offering(offering)
    {
      id: offering.id,
      user_id: offering.user_id,
      service_id: offering.service_id,
      title: offering.service.title,
      duration_minutes: offering.service.duration_minutes,
      description: offering.service.description,
      price: offering.price,
    }
  end
end
