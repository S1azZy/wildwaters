class CreateRegionNames < ActiveRecord::Migration[8.1]
  def up
    enable_extension("pg_trgm") unless extension_enabled?("pg_trgm")

    execute <<~SQL
      CREATE TABLE region_names (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        region_id uuid NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
        import_source_record_id bigint REFERENCES import_source_records(id) ON DELETE SET NULL,
        language_code text,
        name text NOT NULL,
        normalized_name text NOT NULL,
        name_role text NOT NULL,
        preferred boolean NOT NULL DEFAULT FALSE,
        searchable boolean NOT NULL DEFAULT TRUE,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT region_names_name_role_check
          CHECK (name_role IN ('primary', 'official', 'preferred', 'native', 'alias', 'ascii'))
      );
    SQL

    execute <<~SQL
      CREATE INDEX index_region_names_on_region_id ON region_names (region_id);
    SQL

    execute <<~SQL
      CREATE INDEX index_region_names_on_import_source_record_id
        ON region_names (import_source_record_id);
    SQL

    execute <<~SQL
      CREATE INDEX index_region_names_on_language_code ON region_names (language_code);
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_region_names_on_identity
        ON region_names (region_id, COALESCE(language_code, ''), normalized_name, name_role);
    SQL

    execute <<~SQL
      CREATE INDEX index_region_names_on_normalized_name_trgm
        ON region_names USING GIN (normalized_name gin_trgm_ops);
    SQL

    execute <<~SQL
      CREATE INDEX index_region_names_on_name_trgm
        ON region_names USING GIN (name gin_trgm_ops);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS region_names;
    SQL
  end
end
