# frozen_string_literal: true

require_relative "../configs/boot_config"
require_relative "../configs/application_config"

BootConfig.configure do |config|
  config.system.ci = ENV.fetch("CI", false)

  config.server.rails_max_threads = ENV.fetch("RAILS_MAX_THREADS", 5)
  config.server.port = ENV.fetch("PORT", 3000)
  config.server.pidfile = ENV["PIDFILE"]
  config.server.solid_queue_in_puma = ENV.fetch("SOLID_QUEUE_IN_PUMA", false)

  config.jobs.concurrency = ENV.fetch("JOB_CONCURRENCY", 1)
  config.logging.level = ENV.fetch("RAILS_LOG_LEVEL", :info)
  config.security.assume_ssl = ENV.fetch("ASSUME_SSL", false)
  config.security.force_ssl = ENV.fetch("FORCE_SSL", false)
  config.redis.url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

  config.database.pool = ENV.fetch("RAILS_MAX_THREADS", 5)
  config.database.max_connections = ENV.fetch("RAILS_MAX_THREADS", 5)
  config.database.host = ENV.fetch("DB_HOST", "127.0.0.1")
  config.database.port = ENV.fetch("DB_PORT", 5432)
  config.database.username = ENV.fetch("DB_USER", "postgres")
  config.database.password = ENV.fetch("DB_PASSWORD", "postgres")
  config.database.name = ENV.fetch("DB_NAME", "wildwaters_development")
  config.database.cache_name = ENV.fetch("DB_CACHE_NAME", "wildwaters_cache")
  config.database.queue_name = ENV.fetch("DB_QUEUE_NAME", "wildwaters_development_queue")
  config.database.cable_name = ENV.fetch("DB_CABLE_NAME", "wildwaters_cable")
end

ApplicationConfig.configure do |config|
  config.urls.host = ENV.fetch("APP_HOST", "localhost")
  config.urls.port = ENV["APP_PORT"]
  config.urls.protocol = ENV.fetch("APP_PROTOCOL", "http")
  config.storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", :local)

  config.imports.geonames.source_key = ENV.fetch("GEONAMES_SOURCE_KEY", "geonames_regions")
  config.imports.geonames.country_codes = ENV.fetch("GEONAMES_COUNTRIES", "")
  config.imports.geonames.languages = ENV.fetch("GEONAMES_LANGUAGES", "en,ru")
  config.imports.geonames.feature_codes = ENV.fetch("GEONAMES_FEATURE_CODES", "PCLI,ADM1,PPLA,PPLC")
  config.imports.geonames.download_alternate_names = ENV.fetch("GEONAMES_DOWNLOAD_ALTERNATE_NAMES", true)
  config.imports.geonames.default_mode = ENV.fetch("GEONAMES_DEFAULT_MODE", "full")
  config.imports.geonames.download_dir = ENV.fetch("GEONAMES_DOWNLOAD_DIR", "tmp/imports/geonames/geonames_regions")
  config.imports.geonames.all_countries_path = ENV["GEONAMES_ALL_COUNTRIES_PATH"]
  config.imports.geonames.alternate_names_path = ENV["GEONAMES_ALTERNATE_NAMES_PATH"]
end
