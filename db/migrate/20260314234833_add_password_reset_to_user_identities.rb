class AddPasswordResetToUserIdentities < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE user_identities
        ADD COLUMN password_reset_token_digest text,
        ADD COLUMN password_reset_sent_at timestamptz;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_user_identities_on_password_reset_token_digest
        ON user_identities (password_reset_token_digest)
        WHERE password_reset_token_digest IS NOT NULL;
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS index_user_identities_on_password_reset_token_digest;
    SQL

    execute <<~SQL
      ALTER TABLE user_identities
        DROP COLUMN IF EXISTS password_reset_token_digest,
        DROP COLUMN IF EXISTS password_reset_sent_at;
    SQL
  end
end
