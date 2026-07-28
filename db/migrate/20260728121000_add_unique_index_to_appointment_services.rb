class AddUniqueIndexToAppointmentServices < ActiveRecord::Migration[8.1]
  def change
    add_index :appointment_services, [:appointment_id, :service_id], unique: true, name: 'index_appointment_services_on_appointment_id_and_service_id'
  end
end
