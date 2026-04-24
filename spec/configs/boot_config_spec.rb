require "rails_helper"

RSpec.describe BootConfig do
  after do
    load_settings!
  end

  it "loads typed runtime settings from environment overrides" do
    with_boot_env do
      load_settings!

      aggregate_failures do
        expect(described_class.config.system.ci).to be(true)
        expect(described_class.config.server.port).to eq(3100)
        expect(described_class.config.server.rails_max_threads).to eq(7)
        expect(described_class.config.server.solid_queue_in_puma).to be(true)
        expect(described_class.config.jobs.concurrency).to eq(3)
        expect(described_class.config.logging.level).to eq(:debug)
      end
    end
  end

  it "loads typed database settings from environment overrides" do
    with_boot_env do
      load_settings!

      aggregate_failures do
        expect(described_class.config.database.host).to eq("postgres")
        expect(described_class.config.database.port).to eq(5544)
        expect(described_class.config.database.username).to eq("wild")
        expect(described_class.config.database.password).to eq("secret")
        expect(described_class.config.database.name).to eq("wildwaters_current")
        expect(described_class.config.database.queue_name).to eq("wildwaters_current_queue")
      end
    end
  end

  it "loads database defaults from the settings initializer" do
    with_env(default_database_env) do
      load_settings!

      aggregate_failures do
        expect(described_class.config.database.username).to eq("postgres")
        expect(described_class.config.database.host).to eq("127.0.0.1")
        expect(described_class.config.database.name).to eq("wildwaters_development")
        expect(described_class.config.database.queue_name).to eq("wildwaters_development_queue")
      end
    end
  end

  def with_boot_env(&)
    with_env(
      "CI" => "true",
      "PORT" => "3100",
      "RAILS_MAX_THREADS" => "7",
      "JOB_CONCURRENCY" => "3",
      "SOLID_QUEUE_IN_PUMA" => "1",
      "PIDFILE" => "tmp/pids/custom.pid",
      "RAILS_LOG_LEVEL" => "debug",
      "REDIS_URL" => "redis://redis:6379/4",
      "DB_HOST" => "postgres",
      "DB_PORT" => "5544",
      "DB_USER" => "wild",
      "DB_PASSWORD" => "secret",
      "DB_NAME" => "wildwaters_current",
      "DB_QUEUE_NAME" => "wildwaters_current_queue",
      "DB_CACHE_NAME" => "wildwaters_cache",
      "DB_CABLE_NAME" => "wildwaters_cable",
      &
    )
  end

  def default_database_env
    {
      "DB_USER" => nil,
      "DB_HOST" => nil,
      "DB_NAME" => nil,
      "DB_QUEUE_NAME" => nil
    }
  end

  def load_settings!
    load Rails.root.join("config/initializers/01_settings.rb")
  end
end
