# frozen_string_literal: true

require "base64"
require "rexml/document"

module Spid
  class IdentityProviderManager # :nodoc:
    include Singleton

    def self.find_by_entity(entity_id)
      instance.identity_providers.find do |idp|
        idp.entity_id == entity_id
      end
    end

    def identity_providers
      @identity_providers ||= load_identity_providers
    end

    private

    def load_identity_providers
      idps = []
      Dir.chdir(Spid.configuration.idp_metadata_dir_path) do
        Dir.glob("*.xml").each do |metadata_file|
          metadata = File.read(File.expand_path(metadata_file))
          idps.concat(parse_metadata(metadata))
        end
      end
      idps
    end

    def parse_metadata(metadata)
      document = REXML::Document.new(metadata)
      if multiple_entity_descriptors?(document)
        extract_each_entity_descriptor(document)
      else
        [::Spid::Saml2::IdentityProvider.new(metadata:)]
      end
    end

    def multiple_entity_descriptors?(document)
      !REXML::XPath.first(document, "//md:EntitiesDescriptor").nil?
    end

    def extract_each_entity_descriptor(document)
      document.elements.collect("md:EntitiesDescriptor/md:EntityDescriptor") do |entity|
        ::Spid::Saml2::IdentityProvider.new(metadata: entity.to_s)
      end
    end
  end
end
