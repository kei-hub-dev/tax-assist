class CreateJournalEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :journal_entries do |t|
      t.references :accounting_period, null: false, foreign_key: true
      t.integer :entry_no,    null: false
      t.date    :entry_date,  null: false
      t.string  :description, null: false, default: ""
      t.timestamps
    end
    add_index :journal_entries, [ :accounting_period_id, :entry_no ], unique: true
  end
end
