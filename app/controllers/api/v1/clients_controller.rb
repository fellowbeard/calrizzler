class Api::V1::ClientsController < Api::V1::BaseController
  before_action :require_write_access, only: [:create, :update, :destroy]
  before_action :set_client, only: [:show, :update, :destroy]
  before_action :require_owner_or_client_owner, only: [:update, :destroy]

  def index
    clients = current_account.clients.limit(100)

    render json: clients.map { |client| ClientSerializer.new(client).as_json }
  end

  def show
    render json: ClientDetailSerializer.new(@client).as_json
  end

  def create
    client = current_account.clients.new(client_params)
    client.user = current_user

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
    @client = current_account.clients.find(params[:id])
  end

  def require_owner_or_client_owner
    return if current_user.owner?
    return if @client.user_id == current_user.id

    render_error(
      code: 'forbidden',
      message: 'You can only change your own clients.',
      status: :forbidden
    )
  end

  def client_params
    params.require(:client).permit(:first_name, :last_name, :email, :phone)
  end
end
