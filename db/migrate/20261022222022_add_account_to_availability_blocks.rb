
class AddAccountToAvailabilityBlocks < ActiveRecord::Migration[8.1]
  def up
    add_reference :availability_blocks,
                  :account,
                  foreign_key: true

    change_column_null :availability_blocks, :user_id, true

    execute <<~SQL
      UPDATE availability_blocks
      SET account_id = users.account_id
      FROM users
      WHERE availability_blocks.user_id = users.id
    SQL

    change_column_null :availability_blocks, :account_id, false
  end

  def down
    # Business-wide blocks cannot exist without an account.
    execute <<~SQL
      DELETE FROM availability_blocks
      WHERE user_id IS NULL
    SQL

    change_column_null :availability_blocks, :user_id, false

    remove_reference :availability_blocks,
                     :account,
                     foreign_key: true
  end
end
