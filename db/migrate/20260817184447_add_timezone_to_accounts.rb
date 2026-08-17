class AddTimezoneToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :timezone, :string, null: false, default: "America/Denver"
  end
end
