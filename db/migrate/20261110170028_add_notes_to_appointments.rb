class AddNotesToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_column :appointments, :notes, :text
  end
end
