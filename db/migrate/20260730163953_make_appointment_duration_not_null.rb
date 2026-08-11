class MakeAppointmentDurationNotNull < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE appointments
      SET duration_minutes = 0
      WHERE duration_minutes IS NULL
    SQL

    change_column_null :appointments, :duration_minutes, false
  end

  def down
    change_column_null :appointments, :duration_minutes, true
  end
end
