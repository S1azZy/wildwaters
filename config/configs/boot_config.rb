# frozen_string_literal: true

require_relative "configurable"

class BootConfig
  extend Wildwaters::Configurable

  PositiveInteger = Types::Params::Integer.constrained(gt: 0)
  OptionalString = Types::String.optional
  StringBool = Types::Params::Bool
  LogLevel = Types::Symbol.constructor { _1.to_s.downcase.to_sym }
    .enum(:debug, :info, :warn, :error, :fatal, :unknown)

  setting :system do
    setting :ci, default: false, constructor: StringBool
  end

  setting :server do
    setting :rails_max_threads, default: 5, constructor: PositiveInteger
    setting :port, default: 3000, constructor: PositiveInteger
    setting :pidfile, default: nil, constructor: OptionalString
    setting :solid_queue_in_puma, default: false, constructor: StringBool
  end

  setting :jobs do
    setting :concurrency, default: 1, constructor: PositiveInteger
  end

  setting :logging do
    setting :level, default: :info, constructor: LogLevel
  end

  setting :security do
    setting :assume_ssl, default: false, constructor: StringBool
    setting :force_ssl, default: false, constructor: StringBool
  end

  setting :redis do
    setting :url, default: "redis://localhost:6379/1", constructor: Types::String.constrained(filled: true)
  end

  setting :database do
    setting :pool, default: 5, constructor: PositiveInteger
    setting :max_connections, default: 5, constructor: PositiveInteger
    setting :host, default: "127.0.0.1", constructor: Types::String.constrained(filled: true)
    setting :port, default: 5432, constructor: PositiveInteger
    setting :username, default: "postgres", constructor: Types::String.constrained(filled: true)
    setting :password, default: "postgres", constructor: Types::String
    setting :production_password, default: nil, constructor: OptionalString

    setting :development do
      setting :primary_name, default: "wildwaters_development", constructor: Types::String.constrained(filled: true)
      setting :queue_name, default: "wildwaters_development_queue", constructor: Types::String.constrained(filled: true)
    end

    setting :test do
      setting :primary_name, default: "wildwaters_test", constructor: Types::String.constrained(filled: true)
      setting :queue_name, default: "wildwaters_test_queue", constructor: Types::String.constrained(filled: true)
    end

    setting :production do
      setting :host, default: "db", constructor: Types::String.constrained(filled: true)
      setting :username, default: "wildwaters", constructor: Types::String.constrained(filled: true)
      setting :primary_name, default: "wildwaters_production", constructor: Types::String.constrained(filled: true)
      setting :cache_name, default: "wildwaters_production_cache", constructor: Types::String.constrained(filled: true)
      setting :queue_name, default: "wildwaters_production_queue", constructor: Types::String.constrained(filled: true)
      setting :cable_name, default: "wildwaters_production_cable", constructor: Types::String.constrained(filled: true)
    end
  end

  def self.load_from_env!
    configure do |config|
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
      config.database.production_password = ENV["WILDWATERS_DATABASE_PASSWORD"]

      config.database.development.primary_name = ENV.fetch("DB_NAME", "wildwaters_development")
      config.database.development.queue_name = ENV.fetch("DB_QUEUE_NAME", "wildwaters_development_queue")
      config.database.test.primary_name = ENV.fetch("DB_TEST_NAME", "wildwaters_test")
      config.database.test.queue_name = ENV.fetch("DB_TEST_QUEUE_NAME", "wildwaters_test_queue")

      config.database.production.host = ENV.fetch("DB_HOST", "db")
      config.database.production.username = ENV.fetch("DB_USER", "wildwaters")
      config.database.production.primary_name = ENV.fetch("DB_NAME", "wildwaters_production")
      config.database.production.cache_name = ENV.fetch("DB_CACHE_NAME", "wildwaters_production_cache")
      config.database.production.queue_name = ENV.fetch("DB_QUEUE_NAME", "wildwaters_production_queue")
      config.database.production.cable_name = ENV.fetch("DB_CABLE_NAME", "wildwaters_production_cable")
    end
  end
end
