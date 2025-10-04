class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :category

      t.timestamps
    end
    add_index :accounts, [ :user_id, :name ], unique: true
  end
end
