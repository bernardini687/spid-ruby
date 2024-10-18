# frozen_string_literal: true

require "spid/saml2"
require "spid/sso"
require "spid/slo"
require "spid/rack"
require "spid/metadata"
require "spid/cie_metadata"
require "spid/version"
require "spid/configuration"
require "spid/identity_provider_manager"
require "spid/synchronize_idp_metadata"

module Spid # :nodoc:
  class UnknownAuthnComparisonMethodError < StandardError; end
  class UnknownAuthnContextError < StandardError; end
  class UnknownDigestMethodError < StandardError; end
  class UnknownSignatureMethodError < StandardError; end
  class UnknownAttributeFieldError < StandardError; end
  class MissingAttributeServicesError < StandardError; end
  class PrivateKeyTooShortError < StandardError; end
  class CertificateNotBelongsToPKeyError < StandardError; end
  class InvalidOrganizationConfig < StandardError; end
  class InvalidContactPersonConfig < StandardError; end

  EXACT_COMPARISON = :exact
  MINIMUM_COMPARISON = :minimum
  BETTER_COMPARISON = :better
  MAXIMUM_COMPARISON = :maximum

  BINDINGS_HTTP_POST = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
  BINDINGS_HTTP_REDIRECT = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"

  COMPARISON_METHODS = [
    EXACT_COMPARISON,
    MINIMUM_COMPARISON,
    BETTER_COMPARISON,
    MAXIMUM_COMPARISON
  ].freeze

  SHA256 = "http://www.w3.org/2001/04/xmlenc#sha256"
  SHA384 = "http://www.w3.org/2001/04/xmldsig-more#sha384"
  SHA512 = "http://www.w3.org/2001/04/xmlenc#sha512"

  DIGEST_METHODS = [
    SHA256,
    SHA384,
    SHA512
  ].freeze

  RSA_SHA256 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  RSA_SHA384 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384"
  RSA_SHA512 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512"

  SIGNATURE_METHODS = [
    RSA_SHA256,
    RSA_SHA384,
    RSA_SHA512
  ].freeze

  SIGNATURE_ALGORITHMS = {
    SHA256 => OpenSSL::Digest.new("SHA256"),
    SHA384 => OpenSSL::Digest.new("SHA384"),
    SHA512 => OpenSSL::Digest.new("SHA512"),
    RSA_SHA256 => OpenSSL::Digest.new("SHA256"),
    RSA_SHA384 => OpenSSL::Digest.new("SHA384"),
    RSA_SHA512 => OpenSSL::Digest.new("SHA512")
  }.freeze

  L1 = "https://www.spid.gov.it/SpidL1"
  L2 = "https://www.spid.gov.it/SpidL2"
  L3 = "https://www.spid.gov.it/SpidL3"

  AUTHN_CONTEXTS = [
    L1,
    L2,
    L3
  ].freeze

  SUCCESS_CODE = "urn:oasis:names:tc:SAML:2.0:status:Success"

  ATTRIBUTES_MAP = {
    spid_code: "spidCode",
    name: "name",
    family_name: "familyName",
    place_of_birth: "placeOfBirth",
    date_of_birth: "dateOfBirth",
    gender: "gender",
    company_name: "companyName",
    registered_office: "registeredOffice",
    fiscal_number: "fiscalNumber",
    iva_code: "ivaCode",
    id_card: "idCard",
    mobile_phone: "mobilePhone",
    email: "email",
    address: "address",
    digital_address: "digitalAddress"
  }.freeze

  ATTRIBUTES = ATTRIBUTES_MAP.keys.freeze

  ORGANIZATION_REQUIRED_KEYS = %i[name display_name url].freeze
  PUBLIC_CONTACT_REQUIRED_KEYS = %i[public ipa_code email].freeze

  IDP_METADATA_XML_URL = "https://registry.spid.gov.it/entities-idp"
  IDP_METADATA_XML_OUT = "entities-idp.xml"

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end

  def self.configure
    yield configuration
  end
end
