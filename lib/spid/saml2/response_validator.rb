# frozen_string_literal: true

require "xmldsig"

module Spid
  module Saml2
    class ResponseValidator # :nodoc:
      attr_reader :response, :settings, :errors, :request_uuid

      def initialize(response:, settings:, request_uuid:)
        @response = response
        @settings = settings
        @request_uuid = request_uuid
        @errors = {}
      end

      def call
        return false unless success?

        [
          matches_request_uuid, issuer, assertion_issuer, certificate,
          destination, conditions, audience, signature
        ].all?
      end

      def matches_request_uuid
        return true if response.in_response_to == request_uuid

        @errors["request_uuid_mismatch"] =
          "Request uuid not belongs to current session"
        false
      end

      def success?
        return true if response.status_code == Spid::SUCCESS_CODE

        @errors["authentication"] = {
          "status_code" => response.status_code,
          "status_message" => response.status_message,
          "status_detail" => response.status_detail
        }
        false
      end

      def issuer
        return true if response.issuer == settings.idp_entity_id

        @errors["issuer"] =
          begin
            "Response Issuer is '#{response.issuer}' " \
            "but was expected '#{settings.idp_entity_id}'"
          end
        false
      end

      def assertion_issuer
        return true if response.assertion_issuer == settings.idp_entity_id

        @errors["assertion_issuer"] =
          begin
            "Response Assertion Issuer is '#{response.assertion_issuer}' " \
            "but was expected '#{settings.idp_entity_id}'"
          end
        false
      end

      def certificate
        return true if response.certificate.to_der == settings.idp_certificate.to_der

        @errors["certificate"] = "Certificates mismatch"
        false
      end

      def destination
        return true if response.destination == settings.sp_acs_url
        return true if response.destination == settings.sp_entity_id

        @errors["destination"] =
          begin
            "Response Destination is '#{response.destination}' " \
            "but was expected '#{settings.sp_acs_url}'"
          end
        false
      end

      def conditions
        time = Time.now.utc.iso8601

        if response.conditions_not_before <= time &&
           response.conditions_not_on_or_after > time

          return true
        end

        @errors["conditions"] = "Response was out of time"
        false
      end

      def audience
        return true if response.audience == settings.sp_entity_id

        @errors["audience"] =
          begin
            "Response Audience is '#{response.audience}' " \
            "but was expected '#{settings.sp_entity_id}'"
          end
        false
      end

      def signature
        signed_document = Xmldsig::SignedDocument.new(response.saml_message)
        return true if signed_document.validate(response.certificate)

        @errors["signature"] = "Signature mismatch"
        false
      end

      def subject_recipient
        true if response.subject_recipient == settings.sp_acs_url
      end

      def subject_in_response_to
        true if response.subject_in_response_to == request_uuid
      end

      def subject_not_on_or_after
        time = Time.now.utc.iso8601

        true if response.subject_not_on_or_after > time
      end
    end
  end
end
