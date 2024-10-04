# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Spid::Slo::Request conforms SPID specification" do
  let(:slo_request) do
    Spid::Slo::Request.new(idp_name:, session_index:)
  end

  let(:idp_name) { "https://identity.provider" }

  let(:idp_slo_target_url) { "https://identity.provider/slo" }
  let(:sp_entity_id) { "https://service.provider" }
  let(:idp_entity_id) { "https://identity.provider" }
  let(:session_index) { "session-index-value" }
  let(:digest_method) { Spid::SHA256 }
  let(:signature_method) { Spid::RSA_SHA256 }

  let(:idp_metadata_dir_path) { generate_fixture_path("config/idp_metadata") }
  let(:private_key_pem) do
    File.read generate_fixture_path("private-key.pem")
  end

  let(:certificate_pem) do
    File.read generate_fixture_path("certificate.pem")
  end

  before do
    Spid.configure do |config|
      config.hostname = "https://service.provider"
      config.idp_metadata_dir_path = idp_metadata_dir_path
      config.private_key_pem = private_key_pem
      config.certificate_pem = certificate_pem
      config.attribute_services = [
        { name: "Service 1", fields: [:email] }
      ]
      config.organization = { name: "name", display_name: "display_name", url: "url" }
      config.contact_person = { public: true, ipa_code: "ipa_code", email: "email" }
    end
    Timecop.freeze
  end

  after do
    Spid.reset_configuration!
    Timecop.return
  end

  describe "#url" do
    let(:saml_url) { slo_request.url }

    let(:xml_document) { parse_saml_request_from_url(saml_url) }

    let(:document_node) do
      Nokogiri::XML(
        xml_document.to_s
      )
    end

    describe "LogoutRequest node" do
      let(:logout_request_node) do
        document_node.children.find do |child|
          child.name == "LogoutRequest"
        end
      end

      let(:attributes) { logout_request_node.attributes }

      it "exists" do
        expect(logout_request_node).not_to be_nil
      end

      it "contains attribute ID" do
        regexp = /_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
        expect(attributes["ID"].value).to match regexp
      end

      it "contains attribute Version" do
        expect(attributes["Version"].value).to eq "2.0"
      end

      it "contains attribute IssueInstant" do
        expect(attributes["IssueInstant"].value).to eq Time.now.utc.iso8601
      end

      it "contains attribute Destination" do
        expect(attributes["Destination"].value).to eq idp_slo_target_url
      end

      describe "Issuer node" do
        let(:issuer_node) do
          logout_request_node.children.find do |child|
            child.name == "Issuer"
          end
        end

        let(:attributes) { issuer_node.attributes }

        it "exists" do
          expect(issuer_node).not_to be_nil
        end

        it "contains sp_entity_id" do
          expect(issuer_node.text).to eq sp_entity_id
        end

        it "contains attribute Format" do
          attribute = attributes["Format"].value
          expect(attribute).
            to eq "urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
        end

        it "contains attribute NameQualifier" do
          attribute = attributes["NameQualifier"].value
          expect(attribute).to eq sp_entity_id
        end
      end

      describe "nameID" do
        let(:name_id_node) do
          logout_request_node.children.find do |child|
            child.name == "NameID"
          end
        end

        let(:attributes) { name_id_node.attributes }

        it "exists" do
          expect(name_id_node).not_to be_nil
        end

        it "contains attribute Format" do
          attribute = attributes["Format"].value
          expect(attribute).
            to eq "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        end

        it "contains attribute NameQualifier" do
          attribute = attributes["NameQualifier"].value
          expect(attribute).to eq idp_entity_id
        end
      end

      describe "SessionIndex node" do
        let(:session_index_node) do
          logout_request_node.children.find do |child|
            child.name == "SessionIndex"
          end
        end

        it "exists" do
          expect(session_index_node).not_to be_nil
        end

        it "contains provided session index" do
          expect(session_index_node.text).to eq session_index
        end
      end

      describe "Signature node" do
        let(:signature_node) do
          logout_request_node.children.find do |child|
            child.name == "Signature"
          end
        end

        it "doesn't exist" do
          expect(signature_node).to be_nil
        end
      end
    end
  end
end
