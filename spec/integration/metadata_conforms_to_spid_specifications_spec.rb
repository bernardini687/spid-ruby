# frozen_string_literal: true

RSpec.describe "Spid::Metadata conforms to SPID specification" do
  let(:metadata) { Spid::Metadata.new }

  let(:sp_entity_id) { "https://service.provider" }

  let(:assertion_consumer_service_url) { "#{sp_entity_id}/spid/sso" }
  let(:single_logout_service_url) { "#{sp_entity_id}/spid/slo" }

  let(:attribute_services) { [] }
  let(:private_key_pem) do
    File.read generate_fixture_path("private-key.pem")
  end

  let(:certificate_pem) do
    File.read generate_fixture_path("certificate.pem")
  end

  before do
    Spid.configure do |config|
      config.hostname = sp_entity_id
      config.acs_path = "/spid/sso"
      config.slo_path = "/spid/slo"
      config.attribute_services = attribute_services
      config.private_key_pem = private_key_pem
      config.certificate_pem = certificate_pem
      config.attribute_services = [
        { name: "Service 1", fields: [:email] }
      ]
      config.organization = { name: "name", display_name: "display_name", url: "url" }
      config.contact_person = { public: true, ipa_code: "ipa_code", email: "email" }
    end
  end

  describe "#to_xml" do
    let(:xml_document) { metadata.to_xml }

    let(:document_node) do
      Nokogiri::XML(
        xml_document.to_s
      )
    end

    describe "EntityDescriptor node" do
      let(:entity_descriptor_node) do
        document_node.children.find do |child|
          child.name == "EntityDescriptor"
        end
      end

      let(:attributes) { entity_descriptor_node.attributes }

      it "exists" do
        expect(entity_descriptor_node).not_to be_nil
      end

      it "contains attribute entityID" do
        attribute = attributes["entityID"].value
        expect(attribute).to eq sp_entity_id
      end

      describe "Signature node" do
        let(:signature_node) do
          entity_descriptor_node.children.find do |child|
            child.name == "Signature"
          end
        end

        it "exists" do
          expect(signature_node).not_to be_nil
        end

        it "is valid" do
          signed_document = Xmldsig::SignedDocument.new(xml_document)
          certificate = OpenSSL::X509::Certificate.new(certificate_pem)
          validation = signed_document.validate(certificate)

          expect(validation).to be_truthy
        end
      end

      describe "SPSSODescriptor node" do
        let(:sp_sso_descriptor_node) do
          entity_descriptor_node.children.find do |child|
            child.name == "SPSSODescriptor"
          end
        end

        let(:attributes) { sp_sso_descriptor_node.attributes }

        it "contains attribute AuthnRequestsSigned" do
          attribute = attributes["AuthnRequestsSigned"].value
          expect(attribute).to eq "true"
        end

        it "contains attribute protocolSupportEnumeration" do
          attribute = attributes["protocolSupportEnumeration"].value
          expect(attribute).to eq "urn:oasis:names:tc:SAML:2.0:protocol"
        end

        describe "KeyDescriptor node" do
          let(:key_descriptor_node) do
            sp_sso_descriptor_node.children.find do |child|
              child.name == "KeyDescriptor"
            end
          end

          it "exists" do
            expect(key_descriptor_node).not_to be_nil
          end
        end

        describe "SingleLogoutService node" do
          let(:single_logout_service_node) do
            sp_sso_descriptor_node.children.find do |child|
              child.name == "SingleLogoutService"
            end
          end

          let(:attributes) { single_logout_service_node.attributes }

          it "exists" do
            expect(single_logout_service_node).not_to be_nil
          end

          it "contains attribute Binding" do
            attribute = attributes["Binding"].value
            expect(attribute).
              to eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
          end

          it "contains attribute Location" do
            attribute = attributes["Location"].value
            expect(attribute).to eq single_logout_service_url
          end

          pending "Provide HTTP-POST binding"
        end

        describe "AssertionConsumerService node" do
          let(:assertion_consumer_service_node) do
            sp_sso_descriptor_node.children.find do |child|
              child.name == "AssertionConsumerService"
            end
          end

          let(:attributes) { assertion_consumer_service_node.attributes }

          it "exists" do
            expect(assertion_consumer_service_node).not_to be_nil
          end

          it "contains attribute index" do
            attribute = attributes["index"].value
            expect(attribute).to eq "0"
          end

          it "contains attribute isDefault" do
            attribute = attributes["isDefault"].value
            expect(attribute).to eq "true"
          end

          it "contains attribute Binding" do
            attribute = attributes["Binding"].value
            expect(attribute).
              to eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
          end

          it "contains attribute Location" do
            attribute = attributes["Location"].value
            expect(attribute).to eq assertion_consumer_service_url
          end
        end
      end

      describe "Organization node" do
        let(:organization_node) do
          entity_descriptor_node.children.find { |child| child.name == "Organization" }
        end

        it "exists" do
          expect(organization_node).not_to be_nil
        end

        it "has the expected OrganizationName element" do
          element = organization_node.children.find { |child| child.name == "OrganizationName" }
          expect(element.text).to eq "name"
        end

        it "has the expected OrganizationDisplayName element" do
          element = organization_node.children.find { |child| child.name == "OrganizationDisplayName" }
          expect(element.text).to eq "display_name"
        end

        it "has the expected OrganizationURL element" do
          element = organization_node.children.find { |child| child.name == "OrganizationURL" }
          expect(element.text).to eq "url"
        end
      end

      describe "ContactPerson node" do
        let(:contact_person_node) do
          entity_descriptor_node.children.find { |child| child.name == "ContactPerson" }
        end

        it "exists" do
          expect(contact_person_node).not_to be_nil
        end

        it "has the expected contactType attribute" do
          attribute = contact_person_node.attributes["contactType"].value
          expect(attribute).to eq "other"
        end

        it "has the expected EmailAddress element" do
          element = contact_person_node.children.find { |child| child.name == "EmailAddress" }
          expect(element.text).to eq "email"
        end

        describe "Extensions node" do
          let(:extensions_node) do
            contact_person_node.children.find { |child| child.name == "Extensions" }
          end

          it "exists" do
            expect(extensions_node).not_to be_nil
          end

          it "has the Public element" do
            element = extensions_node.children.find { |child| child.name == "Public" }
            expect(element).not_to be_nil
          end

          it "has the expected IPACode element" do
            element = extensions_node.children.find { |child| child.name == "IPACode" }
            expect(element.text).to eq "ipa_code"
          end
        end
      end
    end
  end
end
