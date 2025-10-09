class CreateJournalEntryLines < ActiveRecord::Migration[7.2]
  def change
    create_table :journal_entry_lines do |t|
      t.references :journal_entry, null: false, foreign_key: true
      t.references :account,       null: false, foreign_key: true
      t.string  :dc,     null: false
      t.integer :amount, null: false, default: 0
      t.string  :memo
      t.timestamps
    end
    add_index :journal_entry_lines, [ :journal_entry_id, :account_id ]
  end
end
