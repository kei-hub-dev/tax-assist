class EnforceNotNullOnAccounts < ActiveRecord::Migration[7.2]
  def up
    change_column_null :accounts, :name, false
    change_column_null :accounts, :category, false
  end

  def down
    change_column_null :accounts, :name, true
    change_column_null :accounts, :category, true
  end
end
