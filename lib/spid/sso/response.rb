# frozen_string_literal: true

require "spid/saml2/utils"
require "active_support/inflector/methods"

module Spid
  module Sso
    class Response # :nodoc:
      include Spid::Saml2::Utils

      attr_reader :body, :saml_message, :request_uuid

      def initialize(body:, request_uuid:)
        @body = body
        @saml_message = decode_and_inflate(body)
        @request_uuid = request_uuid
      end

      def valid?
        validator.call
      end

      def validator
        @validator ||=
          Spid::Saml2::ResponseValidator.new(
            response: saml_response,
            settings:,
            request_uuid:
          )
      end

      def issuer
        saml_response.assertion_issuer
      end

      def errors
        validator.errors
      end

      def attributes
        raw_attributes.transform_keys do |key|
          normalize_key(key)
        end
      end

      def session_index
        saml_response.session_index
      end

      def raw_attributes
        saml_response.attributes
      end

      def identity_provider
        @identity_provider ||=
          IdentityProviderManager.find_by_entity(issuer)
      end

      def service_provider
        @service_provider ||=
          Spid.configuration.service_provider
      end

      def saml_response
        @saml_response ||= Spid::Saml2::Response.new(saml_message:)
      end

      def settings
        @settings ||= Spid::Saml2::Settings.new(
          identity_provider:,
          service_provider:
        )
      end

      private

      def normalize_key(key)
        ActiveSupport::Inflector.underscore(
          key.to_s
        ).to_s
      end
    end
  end
end
