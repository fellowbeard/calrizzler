class RemoveUserFromServices < ActiveRecord::Migration[8.1]
  def change
    remove_reference :services, :user, foreign_key: true
  end
end
