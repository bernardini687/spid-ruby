# frozen_string_literal: true

module Spid
  class CieMetadata < Metadata # :nodoc:
    attr_reader :sp_metadata

    # rubocop:disable Lint/MissingSuper
    def initialize
      @sp_metadata = Spid::Saml2::CieSPMetadata.new(settings:)
    end
    # rubocop:enable Lint/MissingSuper
  end
end
