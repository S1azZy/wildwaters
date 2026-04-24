require "rails_helper"

RSpec.describe BootConfig do
  after do
    described_class.load_from_env!
  end

  it "loads typed runtime settings from environment overrides" do
    with_boot_env do
      described_class.load_from_env!

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
      described_class.load_from_env!

      aggregate_failures do
        expect(described_class.config.database.host).to eq("postgres")
        expect(described_class.config.database.port).to eq(5544)
        expect(described_class.config.database.username).to eq("wild")
        expect(described_class.config.database.production_password).to eq("production-secret")
        expect(described_class.config.database.development.primary_name).to eq("wildwaters_dev")
        expect(described_class.config.database.test.primary_name).to eq("wildwaters_spec")
      end
    end
  end

  it "keeps production database defaults separate from local database defaults" do
    with_env("DB_USER" => nil, "DB_HOST" => nil) do
      described_class.load_from_env!

      expect(described_class.config.database.username).to eq("postgres")
      expect(described_class.config.database.production.username).to eq("wildwaters")
      expect(described_class.config.database.host).to eq("127.0.0.1")
      expect(described_class.config.database.production.host).to eq("db")
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
      "DB_NAME" => "wildwaters_dev",
      "DB_QUEUE_NAME" => "wildwaters_dev_queue",
      "DB_TEST_NAME" => "wildwaters_spec",
      "DB_TEST_QUEUE_NAME" => "wildwaters_spec_queue",
      "DB_CACHE_NAME" => "wildwaters_cache",
      "DB_CABLE_NAME" => "wildwaters_cable",
      "WILDWATERS_DATABASE_PASSWORD" => "production-secret",
      &
    )
  end
end
