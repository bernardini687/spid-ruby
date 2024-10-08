# frozen_string_literal: true

module Spid
  module Slo
    class Response # :nodoc:
      include Spid::Saml2::Utils

      attr_reader :body, :session_index, :request_uuid, :saml_message

      def initialize(body:, session_index:, request_uuid:)
        @body = body
        @session_index = session_index
        @request_uuid = request_uuid
        @saml_message = decode_and_inflate(body)
      end

      def valid?
        validator.call
      end

      def response
        []
      end

      def errors
        validator.errors
      end

      def validator
        @validator ||=
          Spid::Saml2::LogoutResponseValidator.new(
            response: saml_response,
            settings:,
            request_uuid:
          )
      end

      def identity_provider
        @identity_provider ||=
          IdentityProviderManager.find_by_entity(issuer)
      end

      def service_provider
        @service_provider ||=
          Spid.configuration.service_provider
      end

      def issuer
        saml_response.issuer
      end

      def settings
        @settings ||= Spid::Saml2::Settings.new(
          service_provider:,
          identity_provider:
        )
      end

      def saml_response
        @saml_response ||= Spid::Saml2::LogoutResponse.new(
          saml_message:
        )
      end
    end
  end
end
