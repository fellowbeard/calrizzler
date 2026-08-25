class CreateUserInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :user_invitations do |t|
      t.references :account, null: false, foreign_key: true

      t.references :invited_by,
                   null: false,
                   foreign_key: { to_table: :users }

      t.string :email, null: false
      t.string :role, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :user_invitations, :token_digest, unique: true
  end
end
