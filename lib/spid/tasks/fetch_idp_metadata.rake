# frozen_string_literal: true

require "spid/synchronize_idp_metadata"

namespace :spid do
  desc "Fetch XML metadata of the SPID Identity Providers and store it in the `config.idp_metadata_dir_path` folder"

  task :fetch_idp_metadata do
    Rake::Task["environment"].invoke if defined?(Rails)
    file_path = Spid::SynchronizeIdpMetadata.new.call

    puts "[Spid] Task saved XML file to: #{file_path}"
  rescue StandardError => e
    puts "[Spid] Task failed to fetch XML file: #{e.message}"
  end
end
