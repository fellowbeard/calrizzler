class Api::V1::NotesController < Api::V1::BaseController
  before_action :require_write_access, only: [:create, :update, :destroy]
  before_action :set_note, only: [:show, :update, :destroy]

  def index
    notes = current_user.notes.order(created_at: :desc)

    render json: notes.map { |note| NoteSerializer.new(note).as_json }
  end

  def show
    render json: NoteSerializer.new(@note).as_json
  end

  def create
    client = current_user.clients.find(note_params[:client_id])

    note = client.notes.new(body: note_params[:body])
    note.user = current_user

    if note.save
      render json: NoteSerializer.new(note).as_json, status: :created
    else
      render_validation_errors(note)
    end
  end

  def update
    if @note.update(body: note_params[:body])
      render json: NoteSerializer.new(@note).as_json
    else
      render_validation_errors(@note)
    end
  end

  def destroy
    @note.destroy
    head :no_content
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:client_id, :body)
  end
end
