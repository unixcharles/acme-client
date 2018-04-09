require 'spec_helper'

describe Acme::Client do
  let(:private_key) { generate_private_key }
  let(:csr) { Acme::Client::CertificateRequest.new(names: %w[example.com]) }

  let(:order) do
    client.new_order(identifiers: [{type: 'dns', value: 'example.com'}])
  end

  let(:unregistered_client) { Acme::Client.new(private_key: private_key, directory: $directory_url) }
  let(:client) do
    client = Acme::Client.new(private_key: private_key, directory: $directory_url)
    client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
    client
  end

  context 'nonce' do
    it 'fetch a new nonce and add it to nonces', vcr: { cassette_name: 'get_nonce' } do
      expect {
        unregistered_client.get_nonce
      }.to change {
        unregistered_client.nonces.empty?
      }.from(true).to(false)
    end
  end

  context 'account operation' do
    context 'new account' do
      it 'accept the terms of service', vcr: { cassette_name: 'new_account_agree_terms' } do
        account = unregistered_client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
        expect(account.status).to eq('valid')
      end

      it 'refuse the terms of service', vcr: { cassette_name: 'new_account_refuse_terms' } do
        expect {
          unregistered_client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: false)
        }.to raise_error(Acme::Client::Error::Malformed)
      end
    end

    context 'account' do
      let(:kid) { client.kid }

      it 'load account when kid is known', vcr: { cassette_name: 'load_account_valid_kid' } do
        client = Acme::Client.new(
          private_key: private_key,
          directory: $directory_url,
          kid: kid
        )

        expect(client.account.status).to eq('valid')
      end

      it 'load account from private key if the kid is unknown', vcr: { cassette_name: 'load_account_unkown_kid' } do
        client = Acme::Client.new(
          private_key: private_key,
          directory: $directory_url
        )

        expect(client.account.status).to eq('valid')
      end
    end

    context 'account update' do
      it 'updates account contact information', vcr: { cassette_name: 'account_contact_update' } do
        expect(
          client.account.contact
        ).to eq(['mailto:info@example.com'])

        client.account_update(contact: 'mailto:updated@example.com')
        expect(
          client.account.contact
        ).to eq(["mailto:updated@example.com"])
      end
    end

    context 'account deactivate' do
      it 'updates account contact information', vcr: { cassette_name: 'account_contact_deactivate' } do
        deactivated_account = client.account_deactivate

        expect(
          deactivated_account.status
        ).to eq('deactivated')
      end
    end
  end

  context 'order operation' do
    context 'new order' do
      it 'creates a new order', vcr: { cassette_name: 'new_order' } do
        order = client.new_order(identifiers:
          [{type: 'dns', value: 'example.com'}]
        )

        expect(order).to be_a(Acme::Client::Resources::Order)
      end

      it 'creates a new order', vcr: { cassette_name: 'simpler_identifiers_order' } do
        order = client.new_order(identifiers: 'example.com')

        expect(order).to be_a(Acme::Client::Resources::Order)
      end
    end

    context 'order' do
      let(:order_url) { order.url }
      it 'fetch orders from a url', vcr: { cassette_name: 'fetch_order' } do
        order = client.order(url: order_url)
        expect(order).to be_a(Acme::Client::Resources::Order)
      end

      it 'fail to fetch order from an invalid url', vcr: { cassette_name: 'fail_fetch_order' } do
        expect {
          client.order(url: "#{order_url}err")
        }.to raise_error(Acme::Client::Error::Malformed, 'Invalid order ID')
      end
    end

    context 'authorization' do
      it 'fetch authorization from a url', vcr: { cassette_name: 'fetch_authorization' } do
        authorization = client.authorization(url: order.authorization_urls.first)
        expect(authorization).to be_a(Acme::Client::Resources::Authorization)
      end
    end

    context 'deactivate_authorization' do
      it 'fetch authorization from a url', vcr: { cassette_name: 'deactivate_authorization' } do
        authorization = client.authorization(url: order.authorization_urls.first)
        authorization = client.deactivate_authorization(url: authorization.url)

        expect(authorization).to be_a(Acme::Client::Resources::Authorization)
        expect(authorization.status).to eq('deactivated')
      end
    end

    context 'challenges' do
      it 'fetch challenges from a url', vcr: { cassette_name: 'fetch_challenge' } do
        authorization = client.authorization(url: order.authorization_urls.first)
        challenge = client.challenge(url: authorization.http01.url)

        expect(challenge).to be_kind_of(Acme::Client::Resources::Challenges::Base)
      end
    end

    context 'request_challenge_validation' do
      it 'request verification from a url', vcr: { cassette_name: 'request_validation' } do
        authorization = client.authorization(url: order.authorization_urls.first)
        challenge = client.challenge(url: authorization.http01.url)
        challenge = client.request_challenge_validation(url: challenge.url, key_authorization: challenge.key_authorization)

        expect(challenge).to be_kind_of(Acme::Client::Resources::Challenges::Base)
        expect(challenge.status).to eq('pending')
      end

      it 'request verification from a url', vcr: { cassette_name: 'request_validation' } do
        authorization = client.authorization(url: order.authorization_urls.first)
        challenge = client.challenge(url: authorization.http01.url)
        challenge = client.request_challenge_validation(url: challenge.url, key_authorization: challenge.key_authorization)

        expect(challenge).to be_kind_of(Acme::Client::Resources::Challenges::Base)
        expect(challenge.status).to eq('pending')
      end
    end

    context 'finalize' do
      let(:order_url) { order.url }
      let(:finalize_url) { order.finalize_url }
      let(:authorization) { client.authorization(url: order.authorization_urls.first) }

      it 'finalize an order raise on csr mismatch', vcr: { cassette_name: 'finalize_csr_mismatch' } do
        expect {
          client.finalize(url: finalize_url, csr: csr)
        }.to raise_error(Acme::Client::Error::Unauthorized)
      end

      it 'finalize an order raise on incomplete authorization', vcr: { cassette_name: 'finalize_incomplete_challenge' } do        
        expect {
          client.finalize(url: finalize_url, csr: csr)
        }.to raise_error(Acme::Client::Error::Unauthorized)
      end

      it 'finalize an order successfully when authorization challenges are completed', vcr: { cassette_name: 'finalize_succeed' } do
        challenge = authorization.http01

        serve_once(challenge.file_content) do
          client.request_challenge_validation(url: challenge.url, key_authorization: challenge.key_authorization)
        end

        order = client.finalize(url: finalize_url, csr: csr)

        finalized_order = client.order(url: order.url)
        expect(finalized_order.certificate_url).not_to be_nil
      end
    end

    context 'certificate' do
      let(:finalize_url) { order.finalize_url }
      let(:authorization) { client.authorization(url: order.authorization_urls.first) }
      let(:challenge) { authorization.http01 }

      it 'download a certificate', vcr: { cassette_name: 'certificate_download' } do
        serve_once(challenge.file_content) do
          client.request_challenge_validation(url: challenge.url, key_authorization: challenge.key_authorization)
        end

        order = client.finalize(url: finalize_url, csr: csr)
        finalized_order = client.order(url: order.url)
        certificate = client.certificate(url: finalized_order.certificate_url)

        expect { OpenSSL::X509::Certificate.new(certificate) }.not_to raise_error
      end
    end

    context 'revoke' do
      let(:finalize_url) { order.finalize_url }
      let(:authorization) { client.authorization(url: order.authorization_urls.first) }
      let(:challenge) { authorization.http01 }
      let(:certificate) do
        serve_once(challenge.file_content) do
          client.request_challenge_validation(url: challenge.url, key_authorization: challenge.key_authorization)
        end

        order = client.finalize(url: finalize_url, csr: csr)
        finalized_order = client.order(url: order.url)
        client.certificate(url: finalized_order.certificate_url)
      end

      # Todo: find a way to record fixtures for this, unsupported by pebble at the moment.
      xit 'revoke a PEM string certificate', vcr: { cassette_name: 'revoke_pem_sucess' } do
        serve_once(challenge.file_content) do
          client.request_challenge_validation(url: challenge.url, key_authorization: challenge.key_authorization)
        end

        order = client.finalize(url: finalize_url, csr: csr)
        finalized_order = client.order(url: order.url)
        certificate = client.certificate(url: finalized_order.certificate_url)

        client.revoke(certificate: certificate)
      end
    end
  end
end
