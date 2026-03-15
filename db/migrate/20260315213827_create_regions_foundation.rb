class CreateRegionsFoundation < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE regions (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        public_id text NOT NULL,
        parent_id uuid REFERENCES regions(id) ON DELETE SET NULL,
        name text NOT NULL,
        slug text NOT NULL,
        region_type text NOT NULL,
        summary text,
        description text,
        external_ref text,
        status text NOT NULL DEFAULT 'active',
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_regions_on_public_id ON regions (public_id);
    SQL

    execute <<~SQL
      CREATE INDEX index_regions_on_parent_id ON regions (parent_id);
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_regions_on_slug_where_parent_id_is_null
        ON regions (slug)
        WHERE parent_id IS NULL;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_regions_on_parent_id_and_slug
        ON regions (parent_id, slug)
        WHERE parent_id IS NOT NULL;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_regions_on_external_ref
        ON regions (external_ref)
        WHERE external_ref IS NOT NULL;
    SQL

    execute <<~SQL
      CREATE INDEX index_regions_on_status ON regions (status);
    SQL

    execute <<~SQL
      CREATE TABLE region_closures (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        ancestor_id uuid NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
        descendant_id uuid NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
        depth integer NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_region_closures_on_ancestor_id_and_descendant_id
        ON region_closures (ancestor_id, descendant_id);
    SQL

    execute <<~SQL
      ALTER TABLE region_closures
        ADD CONSTRAINT region_closures_ancestor_descendant_unique
        UNIQUE USING INDEX index_region_closures_on_ancestor_id_and_descendant_id;
    SQL

    execute <<~SQL
      CREATE INDEX index_region_closures_on_descendant_id ON region_closures (descendant_id);
    SQL

    execute <<~SQL
      CREATE INDEX index_region_closures_on_ancestor_id_and_depth
        ON region_closures (ancestor_id, depth);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS region_closures;
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS regions;
    SQL
  end
end
