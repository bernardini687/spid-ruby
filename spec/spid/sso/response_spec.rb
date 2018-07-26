# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spid::Sso::Response do
  subject(:sso_response) do
    described_class.new(body: response_body)
  end

  let(:response_body) { "SAMLResponse" }

  describe "#service_provider" do
    let(:service_provider) { instance_double("Spid::ServiceProvider") }

    let(:spid_configuration) do
      instance_double(
        "Spid::Configuration",
        service_provider: service_provider
      )
    end

    before do
      allow(Spid).to receive(:configuration).and_return(spid_configuration)
    end

    it "returns a service provider configuration" do
      expect(sso_response.service_provider).to eq service_provider
    end
  end

  describe "#identity_provider" do
    let(:identity_provider) { instance_double("Spid::IdentityProvider") }
    let(:issuer) { "https://identity.provider" }

    before do
      allow(sso_response).
        to receive(:issuer).and_return(issuer)

      allow(Spid::IdentityProviderManager).
        to receive(:find_by_entity).with(issuer).and_return(identity_provider)
    end

    it "returns the identity_provider with provided name" do
      expect(sso_response.identity_provider).to eq identity_provider
    end
  end
end
