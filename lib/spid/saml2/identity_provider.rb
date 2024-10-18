# frozen_string_literal: true

module Spid
  module Saml2
    class IdentityProvider < SamlParser # :nodoc:
      def initialize(metadata:)
        super(saml_message: metadata)
      end

      def entity_id
        entity_id = element_from_xpath(
          "/md:EntityDescriptor/@entityID"
        )
        entity_id ||= element_from_xpath(
          "/EntityDescriptor/@entityID"
        )
        entity_id
      end

      def sso_target_url
        sso_target_url = element_from_xpath(
          "/md:EntityDescriptor/md:IDPSSODescriptor" \
          "/md:SingleSignOnService[@Binding='#{Spid::BINDINGS_HTTP_REDIRECT}']/@Location"
        )
        sso_target_url ||= element_from_xpath(
          "/EntityDescriptor/IDPSSODescriptor" \
          "/SingleSignOnService[@Binding='#{Spid::BINDINGS_HTTP_REDIRECT}']/@Location"
        )
        sso_target_url
      end

      def slo_target_url
        slo_target_url = element_from_xpath(
          "/md:EntityDescriptor/md:IDPSSODescriptor" \
          "/md:SingleLogoutService[@Binding='#{Spid::BINDINGS_HTTP_REDIRECT}']/@Location"
        )
        slo_target_url ||= element_from_xpath(
          "/EntityDescriptor/IDPSSODescriptor" \
          "/SingleLogoutService[@Binding='#{Spid::BINDINGS_HTTP_REDIRECT}']/@Location"
        )
        slo_target_url
      end

      def raw_certificate
        raw_certificate = element_from_xpath(
          "/md:EntityDescriptor/md:IDPSSODescriptor" \
          "/md:KeyDescriptor[@use='signing']/ds:KeyInfo" \
          "/ds:X509Data/ds:X509Certificate/text()"
        )
        raw_certificate ||= element_from_xpath(
          "/EntityDescriptor/IDPSSODescriptor" \
          "/KeyDescriptor[@use='signing']/ds:KeyInfo" \
          "/ds:X509Data/ds:X509Certificate/text()"
        )
        raw_certificate
      end

      def certificate
        certificate_from_encoded_der(raw_certificate)
      end
    end
  end
end
