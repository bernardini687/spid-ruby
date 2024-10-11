# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spid::SynchronizeIdpMetadata do
  subject(:command) { described_class.new }

  let(:metadata_dir_path) do
    "tmp/idp_metadata"
  end

  before do
    Spid.configure do |config|
      config.idp_metadata_dir_path = metadata_dir_path
    end
  end

  it { is_expected.to be_a described_class }

  describe "#call" do
    let(:expected_dir_contents) do
      ["entities-idp.xml"]
    end

    it "save the xml file in the configured metadata dir path", :vcr do
      command.call
      dir_contents = Dir.chdir(metadata_dir_path) do
        Dir.glob("*.xml")
      end

      expect(dir_contents).to match_array expected_dir_contents
    end
  end
end
