# frozen_string_literal: true

module Spid
  module Saml2
    class Response # :nodoc:
      attr_reader :saml_message
      attr_reader :document

      def initialize(saml_message:)
        @saml_message = saml_message
        @document = REXML::Document.new(@saml_message)
      end

      def issuer
        document.elements["/samlp:Response/saml:Issuer/text()"]&.value
      end

      def name_id
        document.elements[
          "/samlp:Response/saml:Assertion/saml:Subject/saml:NameID/text()"
        ]&.value
      end

      def assertion_issuer
        document.elements[
          "/samlp:Response/saml:Assertion/saml:Issuer/text()"
        ]&.value
      end

      def session_index
        document.elements[
          "/samlp:Response/saml:Assertion/saml:AuthnStatement/@SessionIndex"
        ]&.value
      end

      def destination
        document.elements[
          "/samlp:Response/@Destination"
        ]&.value
      end

      def conditions_not_before
        document.elements[
          "/samlp:Response/saml:Assertion/saml:Conditions/@NotBefore"
        ]&.value
      end

      def conditions_not_on_or_after
        document.elements[
          "/samlp:Response/saml:Assertion/saml:Conditions/@NotOnOrAfter"
        ]&.value
      end

      def audience
        xpath = "/samlp:Response/saml:Assertion/saml:Conditions"
        xpath = "#{xpath}/saml:AudienceRestriction/saml:Audience/text()"
        document.elements[xpath]&.value
      end

      def attributes
        main_xpath = "/samlp:Response/saml:Assertion/saml:AttributeStatement"
        main_xpath = "#{main_xpath}/saml:Attribute"

        attributes = REXML::XPath.match(document, main_xpath)
        attributes.each_with_object({}) do |attribute, acc|
          xpath = attribute.xpath

          name = document.elements["#{xpath}/@Name"].value
          value = document.elements["#{xpath}/saml:AttributeValue/text()"].value

          acc[name] = value
        end
      end
    end
  end
end
