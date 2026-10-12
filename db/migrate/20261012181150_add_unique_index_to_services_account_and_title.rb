class AddUniqueIndexToServicesAccountAndTitle < ActiveRecord::Migration[8.1]
  def change
    add_index :services,
              [:account_id, :title],
              unique: true,
              name: 'index_services_on_account_id_and_title'
  end
end