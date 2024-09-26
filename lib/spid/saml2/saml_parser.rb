# frozen_string_literal: true

require "spid/saml2/utils"

module Spid
  module Saml2
    class SamlParser # :nodoc:
      include Spid::Saml2::Utils

      attr_reader :saml_message, :document

      def initialize(saml_message:)
        @saml_message = saml_message
        @document = REXML::Document.new(@saml_message)
      end

      def element_from_xpath(xpath)
        document.elements[xpath]&.value&.strip
      end
    end
  end
end
