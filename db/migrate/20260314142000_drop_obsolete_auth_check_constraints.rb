class DropObsoleteAuthCheckConstraints < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE sessions
      DROP CONSTRAINT IF EXISTS sessions_authentication_method_check;
    SQL

    execute <<~SQL
      ALTER TABLE user_identities
      DROP CONSTRAINT IF EXISTS user_identities_password_provider_check;
    SQL

    execute <<~SQL
      ALTER TABLE user_identities
      DROP CONSTRAINT IF EXISTS user_identities_provider_check;
    SQL

    execute <<~SQL
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS users_locale_check;
    SQL

    execute <<~SQL
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS users_role_check;
    SQL

    execute <<~SQL
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS users_status_check;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Auth check constraints were intentionally removed"
  end
end
