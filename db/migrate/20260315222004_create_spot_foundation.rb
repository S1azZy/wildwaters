class CreateSpotFoundation < ActiveRecord::Migration[8.1]
  def up
    enable_extension("postgis") unless extension_enabled?("postgis")

    execute <<~SQL
      CREATE TABLE spots (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        public_id text NOT NULL,
        region_id uuid NOT NULL REFERENCES regions(id) ON DELETE RESTRICT,
        spot_type text NOT NULL,
        name text NOT NULL,
        slug text NOT NULL,
        summary text,
        description text,
        status text NOT NULL DEFAULT 'draft',
        published_at timestamptz,
        location geography(Point, 4326) NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_spots_on_public_id ON spots (public_id);
    SQL

    execute <<~SQL
      CREATE INDEX index_spots_on_region_id ON spots (region_id);
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_spots_on_region_id_and_slug ON spots (region_id, slug);
    SQL

    execute <<~SQL
      CREATE INDEX index_spots_on_status ON spots (status);
    SQL

    execute <<~SQL
      CREATE INDEX index_spots_on_spot_type ON spots (spot_type);
    SQL

    execute <<~SQL
      CREATE INDEX index_spots_on_location ON spots USING GIST (location);
    SQL

    execute <<~SQL
      CREATE TABLE waterfalls (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        spot_id uuid NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
        height_meters numeric(6,2),
        plunge_pool boolean,
        flow_seasonality text,
        approach_difficulty text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_waterfalls_on_spot_id ON waterfalls (spot_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS waterfalls;
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS spots;
    SQL
  end
end
