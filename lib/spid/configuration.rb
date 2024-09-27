# frozen_string_literal: true

require "logger"

module Spid
  class Configuration # :nodoc:
    attr_accessor :acs_binding, :acs_path, :attribute_services, :certificate_pem, :default_relay_state_path,
                  :digest_method, :hostname, :idp_metadata_dir_path, :logger, :logging_enabled, :login_path,
                  :logout_path, :metadata_path, :private_key_pem, :signature_method, :slo_binding, :slo_path,
                  :org_name, :org_display_name, :org_url

    def initialize
      @idp_metadata_dir_path    = "idp_metadata"
      @attribute_services       = []
      @logging_enabled          = false
      @logger                   = ::Logger.new $stdout
      init_endpoint
      init_bindings
      init_dig_sig_methods
      init_openssl_keys
    end

    def init_endpoint
      @hostname                 = nil
      @metadata_path            = "/spid/metadata"
      @login_path               = "/spid/login"
      @logout_path              = "/spid/logout"
      @acs_path                 = "/spid/sso"
      @slo_path                 = "/spid/slo"
      @default_relay_state_path = "/"
    end

    def init_bindings
      @acs_binding              = Spid::BINDINGS_HTTP_POST
      @slo_binding              = Spid::BINDINGS_HTTP_REDIRECT
    end

    def init_dig_sig_methods
      @digest_method            = Spid::SHA256
      @signature_method         = Spid::RSA_SHA256
    end

    def init_openssl_keys
      @private_key              = nil
      @certificate              = nil
    end

    def init_organization
      @org_name                 = "Acme Corporation"
      @org_display_name         = "Acme"
      @org_url                  = "https://example.com"
    end

    def certificate
      return nil if certificate_pem.nil?

      @certificate ||= OpenSSL::X509::Certificate.new(certificate_pem)
    end

    def private_key
      return nil if private_key_pem.nil?

      @private_key ||= OpenSSL::PKey::RSA.new(private_key_pem)
    end

    def service_provider
      @service_provider ||=
        Spid::Saml2::ServiceProvider.new(
          acs_binding:, acs_path:, slo_path:,
          slo_binding:, metadata_path:,
          private_key:, certificate:,
          digest_method:, signature_method:,
          attribute_services:, host: hostname,
          org_name:, org_display_name:, org_url:
        )
    end
  end
end
