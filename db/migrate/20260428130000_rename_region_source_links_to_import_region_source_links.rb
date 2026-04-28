class RenameRegionSourceLinksToImportRegionSourceLinks < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE region_source_links
        RENAME TO import_region_source_links;
    SQL

    execute <<~SQL
      ALTER SEQUENCE region_source_links_id_seq
        RENAME TO import_region_source_links_id_seq;
    SQL

    rename_constraints(
      from_prefix: "region_source_links",
      to_prefix: "import_region_source_links"
    )
    rename_indexes(
      from_prefix: "index_region_source_links",
      to_prefix: "index_import_region_source_links"
    )
  end

  def down
    rename_indexes(
      from_prefix: "index_import_region_source_links",
      to_prefix: "index_region_source_links"
    )
    rename_constraints(
      from_prefix: "import_region_source_links",
      to_prefix: "region_source_links"
    )

    execute <<~SQL
      ALTER SEQUENCE import_region_source_links_id_seq
        RENAME TO region_source_links_id_seq;
    SQL

    execute <<~SQL
      ALTER TABLE import_region_source_links
        RENAME TO region_source_links;
    SQL
  end

  private

  def rename_constraints(from_prefix:, to_prefix:)
    rename_constraint("#{from_prefix}_confidence_check", "#{to_prefix}_confidence_check")
    rename_constraint("#{from_prefix}_pkey", "#{to_prefix}_pkey")
    rename_constraint("#{from_prefix}_import_source_record_id_fkey", "#{to_prefix}_import_source_record_id_fkey")
    rename_constraint("#{from_prefix}_region_id_fkey", "#{to_prefix}_region_id_fkey")
  end

  def rename_constraint(from_name, to_name)
    execute <<~SQL
      ALTER TABLE import_region_source_links
        RENAME CONSTRAINT #{from_name} TO #{to_name};
    SQL
  end

  def rename_indexes(from_prefix:, to_prefix:)
    rename_index("#{from_prefix}_on_import_source_record_id", "#{to_prefix}_on_import_source_record_id")
    rename_index("#{from_prefix}_on_region_id", "#{to_prefix}_on_region_id")
    rename_index("#{from_prefix}_on_region_id_primary_identity", "#{to_prefix}_on_region_id_primary_identity")
  end

  def rename_index(from_name, to_name)
    execute <<~SQL
      ALTER INDEX #{from_name}
        RENAME TO #{to_name};
    SQL
  end
end
