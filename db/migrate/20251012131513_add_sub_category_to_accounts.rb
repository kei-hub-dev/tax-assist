class AddSubCategoryToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :sub_category, :string
  end
end
