class AddBusinessNameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :business_name, :string
  end
end
