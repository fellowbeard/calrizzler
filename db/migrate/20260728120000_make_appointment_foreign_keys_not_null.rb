class MakeAppointmentForeignKeysNotNull < ActiveRecord::Migration[8.1]
  def up
    change_column_null :appointments, :account_id, false
    change_column_null :appointments, :resource_id, false
    change_column_null :appointments, :user_id, false
  end

  def down
    change_column_null :appointments, :account_id, true
    change_column_null :appointments, :resource_id, true
    change_column_null :appointments, :user_id, true
  end
end
