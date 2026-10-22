
class CreateUserWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :user_working_hours do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :opens_at
      t.time :closes_at
      t.boolean :is_closed, default: false, null: false

      t.timestamps
    end

    add_index :user_working_hours, [:user_id, :day_of_week]

    add_check_constraint :user_working_hours,
                         "day_of_week BETWEEN 0 AND 6",
                         name: "user_working_hours_valid_day"

    add_check_constraint :user_working_hours,
                         <<~SQL,
                           (is_closed = TRUE AND opens_at IS NULL AND closes_at IS NULL)
                           OR
                           (is_closed = FALSE AND opens_at IS NOT NULL
                            AND closes_at IS NOT NULL AND closes_at > opens_at)
                         SQL
                         name: "user_working_hours_valid_times"

    add_index :user_working_hours,
              [:user_id, :day_of_week],
              unique: true,
              where: "is_closed = TRUE",
              name: "index_user_working_hours_unique_closed_day"
  end
end
