# Prepare canonical import source metadata, but keep actual region data loading
# explicit through the GeoNames import tasks documented in the README.

Imports::Source.find_or_initialize_by(key: "geonames_regions").tap do |source|
  source.assign_attributes(
    target_kind: "region",
    source_role: Imports::Source::SOURCE_ROLES[:canonical_identity],
    fetch_mode: Imports::Source::FETCH_MODES[:dump],
    enabled: true,
    license_key: "geonames",
    license_url: "https://www.geonames.org/export/",
    attribution_text: "GeoNames",
    display_policy: Imports::Source::DISPLAY_POLICIES[:public_display_allowed]
  )
  source.config ||= {}
  source.save!
end
