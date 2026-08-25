class Api::V1::ResourcesController < Api::V1::BaseController
  before_action :require_owner, only: [:create, :update, :destroy]
  before_action :set_resource, only: [:show, :update, :destroy]

  def index
    resources = current_account.resources.order(:name)

    render json: resources.map { |resource|
      ResourceSerializer.new(resource).as_json
    }
  end

  def show
    render json: ResourceSerializer.new(@resource).as_json
  end

  def create
    resource = current_account.resources.new(resource_params)

    if resource.save
      render json: ResourceSerializer.new(resource).as_json,
             status: :created
    else
      render_validation_errors(resource)
    end
  end

  def update
    if @resource.update(resource_params)
      render json: ResourceSerializer.new(@resource).as_json
    else
      render_validation_errors(@resource)
    end
  end

  def destroy
    @resource.destroy!
    head :no_content
  end

  private

  def set_resource
    @resource = current_account.resources.find(params[:id])
  end

  def resource_params
    params.require(:resource).permit(:name)
  end
end
