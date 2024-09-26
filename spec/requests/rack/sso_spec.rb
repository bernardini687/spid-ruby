# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Receiving a SSO assertion" do
  let(:app) do
    Rack::Builder.new do
      use Spid::Rack::Sso
      run ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
    end
  end

  let(:request) { Rack::MockRequest.new(app) }

  let(:hostname) { "https://service.provider" }
  let(:acs_path) { "/spid/sso" }

  let(:metadata_dir_path) do
    generate_fixture_path("config/idp_metadata")
  end

  let(:certificate_pem) do
    File.read(generate_fixture_path("certificate.pem"))
  end

  let(:private_key_pem) do
    File.read(generate_fixture_path("private-key.pem"))
  end

  before do
    Spid.configure do |config|
      config.idp_metadata_dir_path = metadata_dir_path
      config.private_key_pem = private_key_pem
      config.certificate_pem = certificate_pem
      config.hostname = hostname
      config.acs_path = acs_path
      config.default_relay_state_path = "/default/relay/state/path"
      config.attribute_services = [
        { name: "Service 1", fields: [:email] }
      ]
    end
    Timecop.freeze
    Timecop.travel("2018-08-04 01:00 +01:00")
  end

  after do
    Spid.reset_configuration!
    Timecop.return
  end

  describe "POST /spid/sso" do
    let(:path) { acs_path.to_s }
    let(:saml_response) do
      File.read(
        generate_fixture_path("sso-response/encoded.base64")
      )
    end

    let(:response) do
      request.post(
        path,
        params: params,
        "rack.session" => rack_session
      )
    end

    let(:rack_session) do
      {
        "spid" => spid_session
      }
    end

    let(:spid_session) do
      {
        "sso_request_uuid" => "_acae2f5c-a008-4cf6-b5b1-df15db7c3dc8",
        "relay_state" => {
          "_opaque-relay-state" => "/path/to/return"
        }
      }
    end

    let(:params) do
      { SAMLResponse: saml_response, RelayState: "_opaque-relay-state" }
    end

    let(:expected_session) do
      a_hash_including(
        "session_index" => "_be9967abd904ddcae3c0eb4189adbe3f71e327cf93",
        "attributes" => a_hash_including(
          "family_name" => "Rossi",
          "spid_code" => "ABCDEFGHILMNOPQ"
        )
      )
    end

    it "responds with 302" do
      expect(response.status).to eq 302
    end

    context "when RelayState is provided by IdP" do
      it "redirects to path provided by RelayState" do
        expect(response.location).to eq "/path/to/return"
      end
    end

    context "when RelayState is not provided by IdP" do
      let(:params) do
        { SAMLResponse: saml_response }
      end

      it "redirects to default relay state path" do
        expect(response.location).to eq "/default/relay/state/path"
      end
    end

    it "sets the session with spid data" do
      response

      spid_data = rack_session["spid"]
      expect(spid_data).to match expected_session
    end

    describe "logging" do
      let(:log_stream) do
        StringIO.new
      end

      before do
        Spid.configure do |config|
          config.logging_enabled = true
          config.logger = Logger.new log_stream
        end
      end

      after do
        Spid.reset_configuration!
      end

      it "logs the saml request" do
        response

        expect(log_stream.string).to match(/samlp:Response/)
      end
    end

    context "when there are errors on response" do
      let(:hostname) { "https://another-service.provider" }

      let(:expected_session) do
        a_hash_including(
          "errors" => {
            "destination" =>
              "Response Destination is 'https://service.provider/spid/sso'" \
              " but was expected 'https://another-service.provider/spid/sso'",
            "audience" =>
              "Response Audience is 'https://service.provider'" \
              " but was expected 'https://another-service.provider'"
          }
        )
      end

      it "sets error message in spid session" do
        response

        expect(rack_session["spid"]).to match expected_session
      end
    end
  end
end
