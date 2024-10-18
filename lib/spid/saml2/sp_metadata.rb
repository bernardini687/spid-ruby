# frozen_string_literal: true

require "xmldsig"

module Spid
  module Saml2
    # rubocop:disable Metrics/ClassLength
    class SPMetadata # :nodoc:
      attr_reader :document, :settings

      def initialize(settings:)
        @document = REXML::Document.new
        @settings = settings
      end

      def to_saml
        signed_document
      end

      private

      def signed_document
        doc = Xmldsig::SignedDocument.new(unsigned_document)
        doc.sign(settings.private_key)
      end

      def unsigned_document
        document.add_element(entity_descriptor)
        document.to_s
      end

      def entity_descriptor
        @entity_descriptor ||=
          begin
            element = REXML::Element.new("md:EntityDescriptor")
            element.add_attributes(entity_descriptor_attributes)
            element.add_element signature
            element.add_element sp_sso_descriptor
            element.add_element organization
            element.add_element public_contact_person
            element
          end
      end

      def entity_descriptor_attributes
        @entity_descriptor_attributes ||= {
          "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
          "xmlns:md" => "urn:oasis:names:tc:SAML:2.0:metadata",
          "xmlns:spid" => "https://spid.gov.it/saml-extensions",
          "entityID" => settings.sp_entity_id,
          "ID" => entity_descriptor_id
        }
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def sp_sso_descriptor
        @sp_sso_descriptor ||=
          begin
            element = REXML::Element.new("md:SPSSODescriptor")
            element.add_attributes(sp_sso_descriptor_attributes)
            element.add_element key_descriptor
            element.add_element slo_service
            element.add_element ac_service
            settings.sp_attribute_services.each.with_index do |service, index|
              name = service[:name]
              fields = service[:fields]
              element.add_element attribute_consuming_service(
                index, name, fields
              )
            end
            element
          end
      end

      def organization
        @organization ||=
          begin
            name, display_name, url = settings.sp_organization.values_at(*ORGANIZATION_REQUIRED_KEYS)

            org = REXML::Element.new("md:Organization")
            org_name = REXML::Element.new("md:OrganizationName", org)
            org_display_name = REXML::Element.new("md:OrganizationDisplayName", org)
            org_url = REXML::Element.new("md:OrganizationURL", org)

            org_name.add_attributes("xml:lang" => "it")
            org_name.text = name
            org_display_name.add_attributes("xml:lang" => "it")
            org_display_name.text = display_name
            org_url.add_attributes("xml:lang" => "it")
            org_url.text = url

            org
          end
      end

      def public_contact_person
        @public_contact_person ||=
          begin
            ipa_code, email = settings.sp_contact_person.values_at(:ipa_code, :email)

            cp = REXML::Element.new("md:ContactPerson")
            cp_extensions = REXML::Element.new("md:Extensions", cp)
            cp_ipa_code = REXML::Element.new("spid:IPACode", cp_extensions)
            cp_email = REXML::Element.new("md:EmailAddress", cp)

            cp.add_attributes("contactType" => "other")
            cp_extensions.add_element(REXML::Element.new("spid:Public"))
            cp_ipa_code.text = ipa_code
            cp_email.text = email

            cp
          end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def signature
        @signature ||= ::Spid::Saml2::XmlSignature.new(
          settings:,
          sign_reference: entity_descriptor_id
        ).signature
      end

      def attribute_consuming_service(index, name, fields)
        element = REXML::Element.new("md:AttributeConsumingService")
        element.add_attributes("index" => index)
        element.add_element service_name(name)
        fields.each do |field|
          element.add_element requested_attribute(field)
        end
        element
      end

      def service_name(name)
        element = REXML::Element.new("md:ServiceName")
        element.add_attributes("xml:lang" => "it")
        element.text = name
        element
      end

      def requested_attribute(name)
        element = REXML::Element.new("md:RequestedAttribute")
        element.add_attributes("Name" => ATTRIBUTES_MAP[name])
        element
      end

      def sp_sso_descriptor_attributes
        @sp_sso_descriptor_attributes ||= {
          "protocolSupportEnumeration" =>
            "urn:oasis:names:tc:SAML:2.0:protocol",
          "AuthnRequestsSigned" => true,
          "WantAssertionsSigned" => true
        }
      end

      def ac_service
        @ac_service ||=
          begin
            element = REXML::Element.new("md:AssertionConsumerService")
            element.add_attributes(ac_service_attributes)
            element
          end
      end

      def ac_service_attributes
        @ac_service_attributes ||= {
          "Binding" => settings.sp_acs_binding,
          "Location" => settings.sp_acs_url,
          "index" => 0,
          "isDefault" => true
        }
      end

      def slo_service
        @slo_service ||=
          begin
            element = REXML::Element.new("md:SingleLogoutService")
            element.add_attributes(
              "Binding" => settings.sp_slo_service_binding,
              "Location" => settings.sp_slo_service_url
            )
            element
          end
      end

      def key_descriptor
        @key_descriptor ||=
          begin
            kd = REXML::Element.new("md:KeyDescriptor")
            kd.add_attributes("use" => "signing")
            ki = kd.add_element "ds:KeyInfo"
            data = ki.add_element "ds:X509Data"
            certificate = data.add_element "ds:X509Certificate"
            certificate.text = settings.x509_certificate_der
            kd
          end
      end

      def entity_descriptor_id
        @entity_descriptor_id ||=
          "_#{Digest::MD5.hexdigest(settings.sp_entity_id)}" # should this match the digest_method config?
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
