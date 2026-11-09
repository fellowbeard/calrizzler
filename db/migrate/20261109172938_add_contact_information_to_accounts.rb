class AddContactInformationToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :phone, :string
    add_column :accounts, :address_line1, :string
    add_column :accounts, :address_line2, :string
    add_column :accounts, :city, :string
    add_column :accounts, :state, :string
    add_column :accounts, :postal_code, :string
  end
end
