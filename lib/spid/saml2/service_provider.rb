# frozen_string_literal: true

require "uri"

module Spid
  module Saml2
    class ServiceProvider # :nodoc:
      attr_reader :host, :acs_path, :acs_binding, :slo_path, :slo_binding, :metadata_path, :private_key, :certificate,
                  :digest_method, :signature_method, :attribute_services, :organization, :contact_person,
                  :cie_metadata_path

      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      def initialize(
        host:,
        acs_path:,
        acs_binding:,
        slo_path:,
        slo_binding:,
        metadata_path:,
        private_key:,
        certificate:,
        digest_method:,
        signature_method:,
        attribute_services:,
        organization:,
        contact_person:,
        cie_metadata_path: nil
      )
        @host = host
        @acs_path               = acs_path
        @acs_binding            = acs_binding
        @slo_path               = slo_path
        @slo_binding            = slo_binding
        @metadata_path          = metadata_path
        @cie_metadata_path      = cie_metadata_path
        @private_key            = private_key
        @certificate            = certificate
        @digest_method          = digest_method
        @signature_method       = signature_method
        @attribute_services     = attribute_services
        @organization           = organization
        @contact_person         = contact_person
        validate_digest_methods
        validate_attributes
        validate_organization
        validate_contact_person
        validate_private_key
        validate_certificate
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/ParameterLists

      def acs_url
        @acs_url ||= URI.join(host, acs_path).to_s
      end

      def slo_url
        @slo_url ||= URI.join(host, slo_path).to_s
      end

      def metadata_url
        @metadata_url ||= URI.join(host, metadata_path).to_s
      end

      private

      def validate_attributes
        if attribute_services.empty?
          raise MissingAttributeServicesError,
                "Provide at least one attribute service"
        elsif attribute_services.any? { |as| !validate_attribute_service(as) }
          raise UnknownAttributeFieldError,
                "Provided attribute in services are not valid: " \
                "use only fields in #{ATTRIBUTES.join(', ')}"
        end
      end

      def validate_attribute_service(attribute_service)
        return false unless attribute_service.key?(:name)
        return false unless attribute_service.key?(:fields)

        not_valid_fields = attribute_service[:fields].map(&:to_sym) - ATTRIBUTES
        not_valid_fields.empty?
      end

      def validate_digest_methods
        if !DIGEST_METHODS.include?(digest_method)
          raise UnknownDigestMethodError,
                "Provided digest method is not valid: " \
                "use one of #{DIGEST_METHODS.join(', ')}"
        elsif !SIGNATURE_METHODS.include?(signature_method)
          raise UnknownSignatureMethodError,
                "Provided digest method is not valid: " \
                "use one of #{SIGNATURE_METHODS.join(', ')}"
        end
      end

      def validate_organization
        missing_keys = ORGANIZATION_REQUIRED_KEYS - organization.keys
        return unless missing_keys.any?

        raise InvalidOrganizationConfig,
              "The following required keys are missing: #{missing_keys.join(', ')}"
      end

      def validate_contact_person
        missing_keys = PUBLIC_CONTACT_REQUIRED_KEYS - contact_person.keys
        if missing_keys.any?
          raise InvalidContactPersonConfig,
                "The following required keys are missing: #{missing_keys.join(', ')}"
        end

        return if [true].include?(contact_person[:public])

        raise InvalidContactPersonConfig,
              "The `:public` key must be `true`"
      end

      def validate_private_key
        return true if private_key.n.num_bits >= 1024

        raise PrivateKeyTooShortError,
              "Private key is too short: provide at least a  " \
              "private key with 1024 bits"
      end

      def validate_certificate
        return true if certificate.verify(private_key)

        raise CertificateNotBelongsToPKeyError,
              "Provided a certificate signed with current private key"
      end
    end
  end
end
