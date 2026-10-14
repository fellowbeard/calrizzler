class AddArchivedAtToServices < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :archived_at, :datetime
  end
end
