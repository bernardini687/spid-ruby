# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Using the Spid::Rack::Logout middleware" do
  let(:app) do
    Rack::Builder.new do
      use Spid::Rack::Logout
      run ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
    end
  end

  let(:request) { Rack::MockRequest.new(app) }

  let(:hostname) { "https://service.provider" }
  let(:slo_path) { "/spid/slo" }

  let(:metadata_dir_path) do
    generate_fixture_path("config/idp_metadata")
  end

  let(:certificate_pem) do
    File.read generate_fixture_path("certificate.pem")
  end

  let(:private_key_pem) do
    File.read generate_fixture_path("private-key.pem")
  end

  let(:default_relay_state_path) { "/path/to/return" }

  let(:attribute_services) do
    [
      { name: "Service 1", fields: [:email] }
    ]
  end

  before do
    Spid.configure do |config|
      config.idp_metadata_dir_path = metadata_dir_path
      config.hostname = hostname
      config.logout_path = slo_path
      config.private_key_pem = private_key_pem
      config.certificate_pem = certificate_pem
      config.default_relay_state_path = default_relay_state_path
      config.attribute_services = attribute_services
      config.organization = { name: "name", display_name: "display_name", url: "url" }
      config.contact_person = { public: true, ipa_code: "ipa_code", email: "email" }
    end
  end

  after do
    Spid.reset_configuration!
  end

  describe "GET logout_path" do
    let(:path) { slo_path.to_s }

    let(:params) { {} }

    let(:response) do
      request.get(
        path,
        params: { idp_name: },
        "rack.session" => {
          "spid" => spid_session
        }
      )
    end

    let(:spid_session) do
      {
        "session_index" => "a-session-index"
      }
    end

    context "with an idp-name" do
      let(:idp_name) { "https://identity.provider" }

      let(:request_uuid) do
        "e2880819-0b3f-48af-903e-fb3558d50042"
      end

      let(:relay_state) do
        "/path/to/return"
      end

      let(:relay_state_id) do
        Digest::MD5.hexdigest(relay_state)
      end

      it "responds with a redirect" do
        expect(response.status).to eq 302
      end

      it "stores in session the uuid of the logout request" do
        allow(SecureRandom).to receive(:uuid).and_return(request_uuid)

        response

        expect(spid_session["slo_request_uuid"]).to eq "_#{request_uuid}"
      end

      it "stores in session the identifier of the relay state" do
        response

        expected_session = a_hash_including(
          "_#{relay_state_id}" => relay_state
        )

        expect(spid_session["relay_state"]).to match expected_session
      end

      describe "Location header url" do
        let(:location) { response.location }
        let(:uri) { URI.parse(location) }

        it "redirects to the slo path of the identity provider" do
          host = "#{uri.scheme}://#{uri.host}#{uri.path}"
          expect(host).to eq "https://identity.provider/slo"
        end

        describe "params" do
          let(:url_params) { CGI.parse(uri.query) }

          [
            "SAMLRequest",
            "SigAlg",
            "RelayState",
            "Signature"
          ].each do |param|
            it "contains #{param}" do
              expect(url_params.keys).to include param
            end
          end
        end
      end
    end

    context "without an idp-name" do
      let(:idp_name) { nil }

      it "returns the app response" do
        expect(response.status).to eq 200
      end

      it "returns the app body" do
        expect(response.body).to eq "OK"
      end
    end
  end

  pending "GET another path"
end
