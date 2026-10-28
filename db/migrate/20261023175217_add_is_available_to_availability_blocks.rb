class AddIsAvailableToAvailabilityBlocks < ActiveRecord::Migration[8.1]
  def change
    add_column :availability_blocks, :is_available, :boolean, default: false, null: false
  end
end
