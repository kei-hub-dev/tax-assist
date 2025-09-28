class AddUniqueIndexOnLowerEmailToUsers < ActiveRecord::Migration[7.2]
  def up
    remove_index :users, :email if index_exists?(:users, :email)

    execute <<~SQL
      CREATE UNIQUE INDEX IF NOT EXISTS index_users_on_lower_email
      ON users (LOWER(email));
    SQL
  end

  def down
    remove_index :users, name: :index_users_on_lower_email if index_exists?(:users, name: :index_users_on_lower_email)
  end
end
