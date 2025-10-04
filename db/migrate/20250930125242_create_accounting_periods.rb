class CreateAccountingPeriods < ActiveRecord::Migration[7.2]
  def change
    create_table :accounting_periods do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :accounting_year
      t.datetime :locked_at

      t.timestamps
    end
    add_index :accounting_periods, [ :user_id, :accounting_year ], unique: true
  end
end
