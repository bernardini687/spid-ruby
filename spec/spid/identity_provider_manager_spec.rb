# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spid::IdentityProviderManager do
  before do
    Spid.configure do |config|
      config.idp_metadata_dir_path = metadata_dir_path
    end
  end

  let(:metadata_dir_path) do
    generate_fixture_path("config/idp_metadata")
  end

  after do
    Spid.reset_configuration!
  end

  describe "#identity_providers" do
    # rubocop:disable RSpec/ExampleLength
    it "returns an array of identity providers for each entity descriptor" do
      idps = described_class.instance.identity_providers

      expect(idps.size).to eq(4)
      expect(idps.map(&:entity_id)).to contain_exactly(
        "https://identity.provider",
        "https://identity.provider",
        "https://multiple.identity.provider1",
        "https://multiple.identity.provider2"
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe ".find_by_entity" do
    it "finds an identity provider by entity_id" do
      idp = described_class.find_by_entity("https://identity.provider")

      expect(idp).not_to be_nil
      expect(idp.entity_id).to eq "https://identity.provider"
    end

    it "returns nil if no identity provider matches the entity_id" do
      idp = described_class.find_by_entity("https://another-identity.provider")

      expect(idp).to be_nil
    end
  end
end
