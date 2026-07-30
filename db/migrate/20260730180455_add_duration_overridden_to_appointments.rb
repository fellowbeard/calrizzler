class AddDurationOverriddenToAppointments < ActiveRecord::Migration[8.1]
  def up
    add_column :appointments,
               :duration_overridden,
               :boolean,
               null: false,
               default: false

    execute <<~SQL
      UPDATE appointments
      SET duration_overridden = TRUE
      WHERE duration_minutes != (
        SELECT COALESCE(SUM(services.duration_minutes), 0)
        FROM appointment_services
        INNER JOIN services
          ON services.id = appointment_services.service_id
        WHERE appointment_services.appointment_id = appointments.id
      )
    SQL
  end

  def down
    remove_column :appointments, :duration_overridden
  end
end