class AddNotNullConstraintsToCoreAccountRelationships < ActiveRecord::Migration[8.1]
  def change
    change_column_null :clients, :account_id, false
    change_column_null :clients, :user_id, false
    change_column_null :users, :account_id, false
    change_column_null :resources, :account_id, false
  end
end
