# frozen_string_literal: true

module Spid
  module Saml2
    class XmlSignature # :nodoc:
      attr_reader :settings, :sign_reference

      def initialize(settings:, sign_reference:)
        @settings = settings
        @sign_reference = sign_reference
      end

      def signature
        @signature ||=
          begin
            element = REXML::Element.new("ds:Signature")
            element.add_element(signed_info)
            element.add_element(signature_value)
            element.add_element(key_info)
            element
          end
      end

      private

      def signed_info
        @signed_info ||=
          begin
            element = REXML::Element.new("ds:SignedInfo")
            element.add_element(canonicalization_method)
            element.add_element(signature_method)
            element.add_element(reference)
            element
          end
      end

      def canonicalization_method
        @canonicalization_method ||=
          begin
            element = REXML::Element.new("ds:CanonicalizationMethod")
            element.add_attributes(
              "Algorithm" => "http://www.w3.org/2001/10/xml-exc-c14n#"
            )
            element
          end
      end

      def signature_method
        @signature_method ||=
          begin
            element = REXML::Element.new("ds:SignatureMethod")
            element.add_attributes("Algorithm" => settings.signature_method)
            element
          end
      end

      def reference
        @reference ||=
          begin
            element = REXML::Element.new("ds:Reference")
            element.add_attributes("URI" => "##{sign_reference}")
            element.add_element(transforms)
            element.add_element(digest_method)
            element.add_element(digest_value)
            element
          end
      end

      def transforms
        @transforms ||=
          begin
            element = REXML::Element.new("ds:Transforms")
            element.add_element(transform_enveloped)
            element.add_element(transform_xml)
            element
          end
      end

      def transform_enveloped
        @transform_enveloped ||=
          begin
            element = REXML::Element.new("ds:Transform")
            element.add_attributes(
              "Algorithm" =>
                "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
            )
            element
          end
      end

      def transform_xml
        @transform_xml ||=
          begin
            element = REXML::Element.new("ds:Transform")
            element.add_attributes(
              "Algorithm" => "http://www.w3.org/2001/10/xml-exc-c14n#"
            )
            element
          end
      end

      def digest_method
        @digest_method ||=
          begin
            element = REXML::Element.new("ds:DigestMethod")
            element.add_attributes("Algorithm" => settings.digest_method)
            element
          end
      end

      def digest_value
        @digest_value ||= REXML::Element.new("ds:DigestValue")
      end

      def signature_value
        @signature_value ||= REXML::Element.new("ds:SignatureValue")
      end

      def key_info
        @key_info ||=
          begin
            element = REXML::Element.new("ds:KeyInfo")
            x509_data = REXML::Element.new("ds:X509Data")
            certificate = REXML::Element.new("ds:X509Certificate")
            certificate.text = settings.x509_certificate_der
            x509_data.add_element(certificate)
            element.add_element(x509_data)
            element
          end
      end
    end
  end
end
