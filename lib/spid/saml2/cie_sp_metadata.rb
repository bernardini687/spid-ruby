# frozen_string_literal: true

require "xmldsig"

module Spid
  module Saml2
    class CieSPMetadata < SPMetadata # :nodoc:
      attr_reader :document, :settings

      def entity_descriptor_attributes
        @entity_descriptor_attributes ||= {
          "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
          "xmlns:md" => "urn:oasis:names:tc:SAML:2.0:metadata",
          "xmlns:cie" => "https://www.cartaidentita.interno.gov.it/saml-extensions",
          "entityID" => settings.sp_entity_id,
          "ID" => entity_descriptor_id
        }
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def public_contact_person
        @public_contact_person ||=
          begin
            cp = REXML::Element.new("md:ContactPerson")
            cp_extensions = REXML::Element.new("md:Extensions", cp)
            cp_ipa_code = REXML::Element.new("cie:IPACode", cp_extensions)
            cp_municipality = REXML::Element.new("cie:Municipality", cp_extensions)
            cp_company = REXML::Element.new("md:Company", cp)
            cp_email = REXML::Element.new("md:EmailAddress", cp)

            cp.add_attributes("contactType" => "administrative")
            cp_extensions.add_element(REXML::Element.new("cie:Public"))
            cp_ipa_code.text = settings.sp_contact_person[:ipa_code]
            cp_municipality.text = settings.sp_contact_person[:municipality]
            cp_company.text = settings.sp_contact_person[:company]
            cp_email.text = settings.sp_contact_person[:email]
            cp
          end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
