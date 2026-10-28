
class CreateWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :working_hours do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :opens_at, null: false
      t.time :closes_at, null: false

      t.timestamps
    end

    add_index :working_hours, [:account_id, :day_of_week]

    add_check_constraint :working_hours,
                         "day_of_week BETWEEN 0 AND 6",
                         name: "working_hours_valid_day"

    add_check_constraint :working_hours,
                         "closes_at > opens_at",
                         name: "working_hours_valid_times"
  end
end
