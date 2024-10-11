# frozen_string_literal: true

require "json"
require "net/http"

module Spid
  class SynchronizeIdpMetadata # :nodoc:
    attr_reader :dir_path

    def initialize
      @dir_path = Spid.configuration.idp_metadata_dir_path
      FileUtils.mkdir_p(@dir_path)
    end

    def call
      file_path = File.join(dir_path, IDP_METADATA_XML_OUT)

      uri = URI(IDP_METADATA_XML_URL)
      response = Net::HTTP.get(uri)
      File.binwrite(file_path, response)

      file_path
    end
  end
end
