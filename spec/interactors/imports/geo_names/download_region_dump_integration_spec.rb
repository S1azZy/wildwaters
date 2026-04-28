require "rails_helper"

RSpec.describe Imports::GeoNames::DownloadRegionDump, type: :interactor do
  subject(:result) do
    described_class.call(
      input: {
        country_code:,
        destination_dir: destination_dir.to_s,
        include_alternate_names:
      }
    )
  end

  let(:country_code) { "AD" }
  let(:destination_dir) { Rails.root.join("tmp/geonames_region_dump_downloader") }
  let(:include_alternate_names) { true }
  let(:success_response_class) { Class.new(Net::HTTPSuccess) }

  before do
    FileUtils.rm_rf(destination_dir)
    allow(Net::HTTP).to receive(:start) do |host, _port, **, &block|
      http = instance_double(Net::HTTP)
      allow(http).to receive(:request) do |request|
        path = request.path
        filename = path.include?("/alternatenames/") ? "AD-alternate" : "AD"
        response_for(filename, path)
      end
      block.call(http)
    end
  end

  after do
    FileUtils.rm_rf(destination_dir)
  end

  it "downloads, extracts, and combines the requested country dumps" do
    expect(result).to be_success
    expect(result.value!).to include(all_countries_path: all_countries_output_path, alternate_names_path: alternate_names_output_path)
    expect(File.read(result.value!.fetch(:all_countries_path))).to eq(expected_country_dump_contents)
    expect(File.read(result.value!.fetch(:alternate_names_path))).to eq(expected_alternate_names_contents)
    expect(Net::HTTP).to have_received(:start).twice
  end

  context "when alternate names are disabled" do
    let(:include_alternate_names) { false }

    it "downloads only the country dump artifacts" do
      expect(result.value!).to include(all_countries_path: destination_dir.join("all_countries.txt").to_s)
      expect(result.value!).not_to have_key(:alternate_names_path)
      expect(File.exist?(destination_dir.join("alternate_names.txt"))).to be(false)
    end
  end

  context "when a response is not successful" do
    before do
      allow(Net::HTTP).to receive(:start) do |_host, _port, **, &block|
        http = instance_double(
          Net::HTTP,
          request: Struct.new(:code, :body) do
            def is_a?(klass)
              false
            end
          end.new("404", "missing")
        )
        block.call(http)
      end
    end

    it "raises a clear download error" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:region_dump_download_failed)
      expect(result.failure[:errors].fetch(:base).first).to match(/Unable to download GeoNames dump for AD/)
    end
  end

  context "when the requested country code is invalid" do
    let(:country_code) { "AND" }

    it "returns a validation failure before any network call" do
      expect(result).to be_failure
      expect(result.failure).to eq(
        code: :validation_error,
        errors: { country_code: [ "is in invalid format" ] }
      )
      expect(Net::HTTP).not_to have_received(:start)
    end
  end

  def response_for(filename, path)
    success_response_class.new("1.1", "200", "OK").tap do |response|
      allow(response).to receive(:body).and_return(zip_body_for(filename, path))
    end
  end

  def zip_body_for(filename, path)
    filename = "AD" if filename == "AD-alternate"
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

  def all_countries_output_path
    destination_dir.join("all_countries.txt").to_s
  end

  def alternate_names_output_path
    destination_dir.join("alternate_names.txt").to_s
  end

  def expected_country_dump_contents
    <<~TEXT
      3041565\tPrincipality of Andorra
    TEXT
  end

  def expected_alternate_names_contents
    <<~TEXT
      1561412\t3041565\tru\tАндорра\t1
    TEXT
  end
end
