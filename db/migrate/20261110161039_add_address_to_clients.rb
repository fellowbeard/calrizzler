class AddAddressToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :address_line1, :string
    add_column :clients, :address_line2, :string
    add_column :clients, :city, :string
    add_column :clients, :state, :string
    add_column :clients, :postal_code, :string
  end
end
