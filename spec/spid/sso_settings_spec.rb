# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spid::SsoSettings do
  subject(:sso_settings) do
    described_class.new(sso_attributes.merge(optional_sso_attributes))
  end

  let(:sso_attributes) do
    {
      service_provider_configuration: service_provider_configuration,
      identity_provider_configuration: identity_provider_configuration
    }
  end

  let(:optional_sso_attributes) { {} }

  let(:identity_provider_configuration) do
    instance_double(
      "Spid::IdentityProviderConfiguration",
      sso_target_url: "https://identity.provider/sso",
      cert_fingerprint: "certificate-fingerprint"
    )
  end

  let(:service_provider_configuration) do
    instance_double(
      "Spid::ServiceProviderConfiguration",
      sso_url: "https://service.provider/sso",
      host: "https://service.provider",
      private_key: "a-private-key",
      certificate: "a-certificate",
      digest_method: "a-digest-method",
      signature_method: "a-signature-method"
    )
  end

  it { is_expected.to be_a described_class }

  it "requires a service provider configuration" do
    expect(sso_settings.service_provider_configuration).
      to eq service_provider_configuration
  end

  it "requires a identity provider configuration" do
    expect(sso_settings.identity_provider_configuration).
      to eq identity_provider_configuration
  end

  describe "AuthnContextComparison" do
    context "when authn_context_comparison is not provided" do
      it "contains :exact value" do
        expect(sso_settings.authn_context_comparison).
          to eq Spid::EXACT_COMPARISON
      end
    end

    [
      Spid::EXACT_COMPARISON,
      Spid::MININUM_COMPARISON,
      Spid::BETTER_COMPARISON,
      Spid::MAXIMUM_COMPARISON
    ].each do |authn_context_comparison|
      context "when provided authn_context_comparison" \
              "is #{authn_context_comparison}" do
        let(:optional_sso_attributes) do
          {
            authn_context_comparison: authn_context_comparison
          }
        end

        it "contains that value" do
          expect(sso_settings.authn_context_comparison).
            to eq authn_context_comparison
        end
      end
    end

    context "when provided authn_context is none of the expected" do
      let(:optional_sso_attributes) do
        {
          authn_context_comparison: "another_authn_comparison"
        }
      end

      it "raises an exception" do
        expect { sso_settings }.
          to raise_error Spid::UnknownAuthnComparisonMethodError
      end
    end
  end

  describe "AuthnContext attribute" do
    context "when authn_context is not provided" do
      it "contains SPIDL1 class" do
        expect(sso_settings.authn_context).to eq Spid::L1
      end
    end

    [
      Spid::L1,
      Spid::L2,
      Spid::L3
    ].each do |authn_context|
      context "when provided authn_context is #{authn_context}" do
        let(:optional_sso_attributes) do
          {
            authn_context: authn_context
          }
        end

        it "contains that class" do
          expect(sso_settings.authn_context).to eq authn_context
        end
      end
    end

    context "when provided authn_context is none of the expected" do
      let(:optional_sso_attributes) do
        {
          authn_context: "another_authn_level"
        }
      end

      it "raises an exception" do
        expect { sso_settings }.
          to raise_error Spid::UnknownAuthnContextError
      end
    end
  end
end
