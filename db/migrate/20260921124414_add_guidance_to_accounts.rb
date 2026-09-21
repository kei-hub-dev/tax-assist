class AddGuidanceToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :guidance, :text
  end
end
