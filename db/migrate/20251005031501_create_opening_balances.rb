class CreateOpeningBalances < ActiveRecord::Migration[7.2]
  def change
    create_table :opening_balances do |t|
      t.references :accounting_period, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.integer :debit_amount, null: false, default: 0
      t.integer :credit_amount, null: false, default: 0
      t.timestamps
    end
    add_index :opening_balances, [ :accounting_period_id, :account_id ], unique: true
  end
end
