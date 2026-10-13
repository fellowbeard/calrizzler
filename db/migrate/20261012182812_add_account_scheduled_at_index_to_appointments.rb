class AddAccountScheduledAtIndexToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_index :appointments,
              [:account_id, :scheduled_at],
              name: 'index_appointments_on_account_and_scheduled_at'
  end
end