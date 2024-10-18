# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Using the Spid::Rack::Metadata middleware" do
  let(:app) do
    Rack::Builder.new do
      use Spid::Rack::Metadata
      run ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
    end
  end

  let(:request) { Rack::MockRequest.new(app) }

  let(:hostname) { "https://service.provider" }
  let(:metadata_path) { "/spid/metadata" }
  let(:cie_metadata_path) { "/cie/metadata" }

  let(:private_key_pem) do
    File.read(generate_fixture_path("private-key.pem"))
  end

  let(:certificate_pem) do
    File.read(generate_fixture_path("certificate.pem"))
  end

  let(:metadata_dir_path) do
    generate_fixture_path("config/idp_metadata")
  end

  let(:attribute_services) do
    [
      { name: "Service 1", fields: [:email] }
    ]
  end

  before do
    Spid.configure do |config|
      config.idp_metadata_dir_path = metadata_dir_path
      config.private_key_pem = private_key_pem
      config.certificate_pem = certificate_pem
      config.hostname = hostname
      config.metadata_path = metadata_path
      config.cie_metadata_path = cie_metadata_path
      config.attribute_services = attribute_services
      config.organization = { name: "name", display_name: "display_name", url: "url" }
      config.contact_person = { public: true, ipa_code: "ipa_code", email: "email" }
    end
  end

  after do
    Spid.reset_configuration!
  end

  describe "GET metadata_path" do
    let(:path) { metadata_path.to_s }

    before do
      allow(Spid::Metadata).to receive(:new).and_call_original
    end

    context "with an idp-name" do
      let(:response) do
        request.get(path)
      end

      it "responds with 200" do
        expect(response).to be_ok
      end

      it "doens't return application body" do
        expect(response.body).not_to eq "OK"
      end

      it "set the 'Content-Type' header with 'application/xml'" do
        content_type_header = response.headers["Content-Type"]
        expect(content_type_header).to eq "application/xml"
      end

      it "uses the Spid::Metadata class" do
        request.get(path)
        expect(Spid::Metadata).to have_received(:new).once
      end
    end
  end

  describe "GET cie_metadata_path" do
    let(:path) { cie_metadata_path.to_s }
    let(:response) do
      request.get(path)
    end

    before do
      allow(Spid::CieMetadata).to receive(:new).and_call_original
    end

    it "responds with 200" do
      expect(response).to be_ok
    end

    it "doesn't return application body" do
      expect(response.body).not_to eq "OK"
    end

    it "sets the 'Content-Type' header with 'application/xml'" do
      content_type_header = response.headers["Content-Type"]
      expect(content_type_header).to eq "application/xml"
    end

    it "uses the Spid::CieMetadata class" do
      request.get(path)
      expect(Spid::CieMetadata).to have_received(:new).once
    end

    context "when cie_metadata_path is not configured" do
      before do
        Spid.configure do |config|
          config.cie_metadata_path = nil
        end
      end

      let(:path) { "/cie/metadata" }

      let(:response) do
        request.get(path)
      end

      it "responds with 200" do
        expect(response).to be_ok
        expect(response.body).to eq "OK"
      end

      it "does not set the 'Content-Type' header to 'application/xml'" do
        content_type_header = response.headers["Content-Type"]
        expect(content_type_header).not_to eq "application/xml"
      end

      it "does not use the Spid::CieMetadata class" do
        expect(Spid::CieMetadata).not_to have_received(:new)
      end
    end
  end
end
