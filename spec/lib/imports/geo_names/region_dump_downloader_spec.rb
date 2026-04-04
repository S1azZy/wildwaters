require "rails_helper"
require Rails.root.join("app/lib/imports/geonames/region_dump_downloader")

RSpec.describe Imports::GeoNames::RegionDumpDownloader do
  subject(:result) do
    described_class.call(
      country_codes:,
      destination_dir:,
      include_alternate_names:,
      http_getter:
    )
  end

  let(:country_codes) { %w[AD FR] }
  let(:destination_dir) { Rails.root.join("tmp/geonames_region_dump_downloader") }
  let(:include_alternate_names) { true }
  let(:http_getter) do
    lambda do |uri, **|
      filename = File.basename(uri.path, ".zip")
      response_for(filename, uri.path)
    end
  end
  let(:success_response_class) { Class.new(Net::HTTPSuccess) }

  before do
    FileUtils.rm_rf(destination_dir)
  end

  after do
    FileUtils.rm_rf(destination_dir)
  end

  it "downloads, extracts, and combines the requested country dumps" do
    expect(result).to include(
      all_countries_path: destination_dir.join("all_countries.txt").to_s,
      alternate_names_path: destination_dir.join("alternate_names.txt").to_s
    )
    expect(File.read(result.fetch(:all_countries_path))).to eq(
      <<~TEXT
        3041565\tPrincipality of Andorra
        3017382\tFrance
      TEXT
    )
    expect(File.read(result.fetch(:alternate_names_path))).to eq(
      <<~TEXT
        1561412\t3041565\tru\tАндорра\t1
        1375070\t3017382\tru\tФранция\t1
      TEXT
    )
  end

  context "when alternate names are disabled" do
    let(:include_alternate_names) { false }

    it "downloads only the country dump artifacts" do
      expect(result).to include(all_countries_path: destination_dir.join("all_countries.txt").to_s)
      expect(result).not_to have_key(:alternate_names_path)
      expect(File.exist?(destination_dir.join("alternate_names.txt"))).to be(false)
    end
  end

  context "when a response is not successful" do
    let(:http_getter) do
      lambda do |uri, **|
        Struct.new(:code, :body) do
          def is_a?(klass)
            false
          end
        end.new("404", "missing: #{uri}")
      end
    end

    it "raises a clear download error" do
      expect { result }.to raise_error(
        Imports::GeoNames::RegionDumpDownloader::Error,
        /Unable to download GeoNames dump for AD/
      )
    end
  end

  context "when the requested country code is invalid" do
    let(:country_codes) { [ "AND" ] }

    it "fails before any network call" do
      expect { result }.to raise_error(
        Imports::GeoNames::RegionDumpDownloader::Error,
        "country_codes must contain two-letter ISO codes"
      )
    end
  end

  def response_for(filename, path)
    success_response_class.new("1.1", "200", "OK").tap do |response|
      allow(response).to receive(:body).and_return(zip_body_for(filename, path))
    end
  end

  def zip_body_for(filename, path)
    content = if path.include?("/alternatenames/")
      alternate_name_content_for(filename)
    else
      country_content_for(filename)
    end

    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("#{filename}.txt")
      zip.write(content)
    end.string
  end

  def country_content_for(filename)
    case filename
    when "AD"
      "3041565\tPrincipality of Andorra\n"
    when "FR"
      "3017382\tFrance\n"
    else
      raise "unexpected filename #{filename}"
    end
  end

  def alternate_name_content_for(filename)
    case filename
    when "AD"
      "1561412\t3041565\tru\tАндорра\t1\n"
    when "FR"
      "1375070\t3017382\tru\tФранция\t1\n"
    else
      raise "unexpected filename #{filename}"
    end
  end
end
