# frozen_string_literal: true

require "spid/synchronize_idp_metadata"

namespace :spid do
  desc "Fetch XML metadata of the SPID Identity Providers and store it in the `config.idp_metadata_dir_path` folder"
  task :fetch_idp_metadata do
    Rake::Task["environment"].invoke if defined?(Rails)
    file_path = Spid::SynchronizeIdpMetadata.new.call
    puts "XML file saved to: #{file_path}"
  end
end
