class Api::V1::ClientsController < Api::V1::BaseController
  before_action :require_write_access, only: [:create, :update, :destroy]
  before_action :set_client, only: [:show, :update, :destroy]

  def index
    clients = current_user.clients.limit(100)

    render json: clients.map { |client| ClientSerializer.new(client).as_json }
  end

  def show
    render json: ClientDetailSerializer.new(@client).as_json
  end

  def create
    client = current_user.clients.new(client_params)
    client.account = current_account

    if client.save
      render json: ClientSerializer.new(client).as_json, status: :created
    else
      render_validation_errors(client)
    end
  end

  def update
    if @client.update(client_params)
      render json: ClientDetailSerializer.new(@client).as_json
    else
      render_validation_errors(@client)
    end
  end

  def destroy
    @client.destroy!
    head :no_content
  end

  private

  def set_client
    @client = current_user.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(
      :first_name,
      :last_name,
      :email,
      :phone
    )
  end
end
