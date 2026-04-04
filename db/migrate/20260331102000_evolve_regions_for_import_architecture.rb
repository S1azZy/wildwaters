class EvolveRegionsForImportArchitecture < ActiveRecord::Migration[8.1]
  def up
    enable_extension("postgis") unless extension_enabled?("postgis")

    execute <<~SQL
      ALTER TABLE regions
        RENAME COLUMN region_type TO region_kind;
    SQL

    execute <<~SQL
      UPDATE regions
      SET region_kind = CASE region_kind
        WHEN 'macroregion' THEN 'area'
        WHEN 'admin_area' THEN 'area'
        ELSE region_kind
      END;
    SQL

    execute <<~SQL
      ALTER TABLE regions
        ADD COLUMN country_code text,
        ADD COLUMN center geography(Point, 4326);
    SQL

    execute <<~SQL
      CREATE INDEX index_regions_on_country_code ON regions (country_code);
    SQL

    execute <<~SQL
      DROP INDEX IF EXISTS index_regions_on_external_ref;
    SQL

    execute <<~SQL
      ALTER TABLE regions
        DROP COLUMN external_ref;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE regions
        ADD COLUMN external_ref text;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_regions_on_external_ref
        ON regions (external_ref)
        WHERE external_ref IS NOT NULL;
    SQL

    execute <<~SQL
      UPDATE regions
      SET region_kind = CASE
        WHEN region_kind = 'area' AND parent_id IS NULL AND country_code IS NULL THEN 'macroregion'
        WHEN region_kind = 'area' THEN 'admin_area'
        ELSE region_kind
      END;
    SQL

    execute <<~SQL
      DROP INDEX IF EXISTS index_regions_on_country_code;
    SQL

    execute <<~SQL
      ALTER TABLE regions
        DROP COLUMN center,
        DROP COLUMN country_code;
    SQL

    execute <<~SQL
      ALTER TABLE regions
        RENAME COLUMN region_kind TO region_type;
    SQL
  end
end
