# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spid::Saml2::ServiceProvider do
  subject(:service_provider) { described_class.new(**service_provider_attributes) }

  let(:service_provider_attributes) do
    {
      host:,
      acs_path:,
      acs_binding:,
      slo_path:,
      slo_binding:,
      metadata_path:,
      cie_metadata_path:,
      private_key:,
      certificate:,
      digest_method:,
      signature_method:,
      attribute_services:,
      organization:,
      contact_person:
    }
  end

  let(:host) { "https://service.provider" }
  let(:attribute_services) { [{ name: "Service 1", fields: [:email] }] }
  let(:organization) { { name: "name", display_name: "display_name", url: "url" } }
  let(:contact_person) { { public: true, ipa_code: "ipa_code", email: "email" } }
  let(:acs_path) { "/sso" }
  let(:acs_binding) { "acs-binding-method" }
  let(:slo_path) { "/slo" }
  let(:slo_binding) { "slo-binding-method" }
  let(:metadata_path) { "/metadata" }
  let(:cie_metadata_path) { nil }
  let(:private_key_path) { generate_fixture_path("private-key.pem") }
  let(:certificate_path) { generate_fixture_path("certificate.pem") }
  let(:digest_method) { Spid::SHA256 }
  let(:signature_method) { Spid::RSA_SHA256 }
  let(:private_key) do
    OpenSSL::PKey::RSA.new(File.read(private_key_path))
  end

  let(:certificate) do
    OpenSSL::X509::Certificate.new(File.read(certificate_path))
  end

  it { is_expected.to be_a described_class }

  context "when attribute services is empty" do
    let(:attribute_services) { [] }

    it "raises a Spid::MissingAttributeServicesError error" do
      expect { service_provider }.
        to raise_error Spid::MissingAttributeServicesError
    end
  end

  context "when organization is empty" do
    let(:organization) { {} }

    it "raises a Spid::InvalidOrganizationConfig error" do
      expect { service_provider }.
        to raise_error Spid::InvalidOrganizationConfig,
                       "The following required keys are missing: name, display_name, url"
    end
  end

  context "when contact_person is empty" do
    let(:contact_person) { {} }

    it "raises a Spid::InvalidContactPersonConfig error" do
      expect { service_provider }.
        to raise_error Spid::InvalidContactPersonConfig,
                       "The following required keys are missing: public, ipa_code, email"
    end
  end

  context "when contact_person is not public" do
    let(:contact_person) { { public: false, ipa_code: "ipa_code", email: "email" } }

    it "raises a Spid::InvalidContactPersonConfig error" do
      expect { service_provider }.
        to raise_error Spid::InvalidContactPersonConfig,
                       "The `:public` key must be `true`"
    end
  end

  context "when cie_metadata_path is set" do
    let(:cie_metadata_path) { "/cie/metadata" }

    it "requires contact_person to have more keys" do
      expect { service_provider }.
        to raise_error Spid::InvalidContactPersonConfig,
                       "The following required keys are missing: municipality, company"
    end
  end

  it "requires an host" do
    expect(service_provider.host).to eq host
  end

  it "requires a sso path" do
    expect(service_provider.acs_path).to eq acs_path
  end

  it "requires a slo path" do
    expect(service_provider.slo_path).to eq slo_path
  end

  it "requires a slo binding" do
    expect(service_provider.slo_binding).to eq slo_binding
  end

  it "requires a metadata path" do
    expect(service_provider.metadata_path).to eq metadata_path
  end

  it "requires a private key file path" do
    expect(service_provider.private_key).to eq private_key
  end

  it "requires a certificate file path" do
    expect(service_provider.certificate).to eq certificate
  end

  it "requires a digest method" do
    expect(service_provider.digest_method).to eq digest_method
  end

  it "requires a signature method" do
    expect(service_provider.signature_method).to eq signature_method
  end

  it "requires a attribute_services" do
    expect(service_provider.attribute_services).to eq attribute_services
  end

  context "with invalid digest methods" do
    let(:digest_method) { "a-not-valid-digest-method" }

    it "raises a Spid::NotValidDigestMethodError" do
      expect { service_provider }.
        to raise_error Spid::UnknownDigestMethodError
    end
  end

  context "with invalid signature methods" do
    let(:signature_method) { "a-not-valid-signature-method" }

    it "raises a Spid::UnknownSignatureMethodError" do
      expect { service_provider }.
        to raise_error Spid::UnknownSignatureMethodError
    end
  end

  context "with wrong attribute in attribute services" do
    let(:attribute_services) do
      [
        { name: "Service 1", fields: [:fiscal_number] },
        { name: "Service 2", fields: [:wrong_attribute] }
      ]
    end

    it "raises a Spid::UknownAttributeFieldError" do
      expect { service_provider }.
        to raise_error Spid::UnknownAttributeFieldError
    end
  end

  context "with a private_key with less of 1024 bit of encoding" do
    let(:private_key) do
      OpenSSL::PKey::RSA.new(1023)
    end

    it "raises a Spid::PrivateKeyTooShortError" do
      expect { service_provider }.
        to raise_error Spid::PrivateKeyTooShortError
    end
  end

  context "with a certificate that was not generated by provided pkey" do
    let(:certificate_path) do
      generate_fixture_path("idp-certificate.pem")
    end

    it "raises a Spid::CertificateNotBelongsToPKeyError" do
      expect { service_provider }.
        to raise_error Spid::CertificateNotBelongsToPKeyError
    end
  end

  describe "#acs_url" do
    it "generates the sso url" do
      expect(service_provider.acs_url).to eq "https://service.provider/sso"
    end
  end

  describe "#slot_url" do
    it "generates the slo url" do
      expect(service_provider.slo_url).to eq "https://service.provider/slo"
    end
  end

  describe "#metadata_url" do
    it "generates the metadata url" do
      expect(service_provider.metadata_url).
        to eq "https://service.provider/metadata"
    end
  end
end
