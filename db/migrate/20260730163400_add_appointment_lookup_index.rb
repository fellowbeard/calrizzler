class AddAppointmentLookupIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :appointments,
              [:account_id, :resource_id, :scheduled_at],
              name: "index_appointments_on_account_resource_time"
  end
end
