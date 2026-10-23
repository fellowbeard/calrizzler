class CreateAvailabilityBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :availability_blocks do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end

    add_check_constraint :availability_blocks,
                         "ends_at > starts_at",
                         name: "availability_blocks_valid_times"

    add_index :availability_blocks,
              [:user_id, :starts_at, :ends_at],
              name: "index_availability_blocks_on_user_and_times"
  end
end
