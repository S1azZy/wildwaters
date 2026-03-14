class AddTokenDigestToSessions < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE sessions
      ADD COLUMN token_digest text;
    SQL

    execute <<~SQL
      UPDATE sessions
      SET token_digest = md5(id::text || clock_timestamp()::text)
      WHERE token_digest IS NULL;
    SQL

    execute <<~SQL
      ALTER TABLE sessions
      ALTER COLUMN token_digest SET NOT NULL;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_sessions_on_token_digest ON sessions (token_digest);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS index_sessions_on_token_digest;
    SQL

    execute <<~SQL
      ALTER TABLE sessions
      DROP COLUMN IF EXISTS token_digest;
    SQL
  end
end
