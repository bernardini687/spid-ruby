# frozen_string_literal: true

require "base64"

module Spid
  module Saml2
    module Utils
      class QueryParamsSigner # :nodoc:
        include Spid::Saml2::Utils

        attr_reader :saml_message, :private_key, :signature_method, :relay_state

        def initialize(
          saml_message:,
          private_key:,
          signature_method:,
          relay_state: nil
        )
          @saml_message = saml_message.delete("\n")
          @private_key = private_key
          @signature_method = signature_method
          @relay_state = relay_state
        end

        def signature_algorithm
          @signature_algorithm ||= Spid::SIGNATURE_ALGORITHMS[signature_method]
        end

        def signature
          @signature ||=
            encode(raw_signature)
        end

        def signed_query_params
          params_for_signature.merge(
            "Signature" => signature
          )
        end

        def escaped_signed_query_string
          @escaped_signed_query_string ||=
            escaped_query_string(signed_query_params)
        end

        def raw_signature
          @raw_signature ||=
            private_key.sign(
              signature_algorithm,
              escaped_query_string(params_for_signature)
            )
        end

        def params_for_signature
          @params_for_signature ||=
            begin
              params = {
                "SAMLRequest" => deflate_and_encode(saml_message),
                "RelayState" => relay_state,
                "SigAlg" => signature_method
              }
              params.delete("RelayState") if params["RelayState"].nil?
              params
            end
        end
      end
    end
  end
end
