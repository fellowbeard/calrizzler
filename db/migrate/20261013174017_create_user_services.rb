class CreateUserServices < ActiveRecord::Migration[8.1]
  def change
    create_table :user_services do |t|
      t.references :user, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :user_services,
          [:user_id, :service_id],
          unique: true
  end
end
