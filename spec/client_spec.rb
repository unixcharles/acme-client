require 'spec_helper'

describe Acme::Client do
  let(:private_key) { generate_private_key }
  let(:csr) { Acme::Client::CertificateRequest.new(names: %w[example.com]) }

  let(:order) do
    client.new_order(identifiers: [{ type: 'dns', value: 'example.com' }])
  end

  let(:unregistered_client) { Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL) }
  let(:client) do
    client = Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL)
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

    it 'raise when nonce fail', vcr: { cassette_name: 'nonce_fail' } do
      expect {
        unregistered_client.new_account(contact: 'mailto:info@example.com')
      }.to raise_error(Acme::Client::Error::BadNonce)
    end

    it 'retry on bad nonce with bad_nonce_retry option', vcr: { cassette_name: 'nonce_retry' }, pending: "Is NONCE required for new_account?" do
      client = Acme::Client.new(private_key: private_key, bad_nonce_retry: 10, directory: DIRECTORY_URL)
      client.nonces << 'invalid_nonce'
      client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
    end
  end

  context 'meta', vcr: { cassette_name: 'client_meta' } do
    it { expect(client.meta).to be_a(Hash) }
    it { expect(client.terms_of_service).to be_a(String) }
    it { expect(client.external_account_required).to be_nil }
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
        }.to raise_error(Acme::Client::Error, 'Provided account did not agree to the terms of service')
      end

      let(:hmac_key) { 'ZzAJzgctYHnssCwf5swk1z1gC-bplzulO2fF3uwYUvyPsfug7OvSmp-xmZTy7uPqM1qP54gwj_CJM8sjpDJhfw' }
      let(:kid) { 'sl61UO7lKgS0VOSO2BnQ9A' }
      it 'use an invalid external account binding', vcr: { cassette_name: 'new_account_invalid_external_binding' } do
        expect {
          unregistered_client.new_account(
            contact: 'mailto:info@example.com',
            terms_of_service_agreed: true,
            external_account_binding: { kid: kid, hmac_key: hmac_key }
          )
        }.to raise_error(Acme::Client::Error)
      end

      let(:hmac_key) { 'FEkpgzzQZUQ7qgBp3Ewa7VodVjFJMkX1l0aVXK2J_o3cQFZhuoDatKIymXJCl8v06Q0Wc56BASDtof2MZPT3gg' }
      let(:kid) { 'AfAr-z9i9WvdIz5hgdtKBA' }
      it 'use an valid external account binding', vcr: { cassette_name: 'new_account_valid_external_binding' } do
        account = unregistered_client.new_account(
          contact: 'mailto:info@example.com',
          terms_of_service_agreed: true,
          external_account_binding: { kid: kid, hmac_key: hmac_key }
        )
        expect(account.status).to eq('valid')
      end
    end

    context 'account' do
      let(:kid) { client.kid }

      it 'load account when kid is known', vcr: { cassette_name: 'load_account_valid_kid' } do
        client = Acme::Client.new(
          private_key: private_key,
          directory: DIRECTORY_URL,
          kid: kid
        )

        expect(client.account.status).to eq('valid')
      end

      it 'load account from private key if the kid is unknown', vcr: { cassette_name: 'load_account_unkown_kid' } do
        account = unregistered_client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
        client = Acme::Client.new(
          private_key: private_key,
          directory: DIRECTORY_URL
        )

        expect(client.account.status).to eq('valid')
        expect(client.account.kid).to eq(account.kid)
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
        ).to eq(['mailto:updated@example.com'])
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

    context 'account key change' do
      it 'changes the key', vcr: { cassette_name: 'account_key_change' } do
        client.account_key_change(new_private_key: generate_private_key)

        expect(client.account.status).to eq('valid')
      end
    end
  end

  context 'order operation' do
    context 'new order' do
      it 'creates a new order', vcr: { cassette_name: 'new_order' } do
        order = client.new_order(identifiers: [{ type: 'dns', value: 'example.com' }])

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
        }.to raise_error(Acme::Client::Error::NotFound)
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
        challenge = client.request_challenge_validation(url: challenge.url)

        expect(challenge).to be_kind_of(Acme::Client::Resources::Challenges::Base)
        expect(challenge.status).to eq('pending')
      end

      it 'request verification from a url', vcr: { cassette_name: 'request_validation' } do
        authorization = client.authorization(url: order.authorization_urls.first)
        challenge = client.challenge(url: authorization.http01.url)
        challenge = client.request_challenge_validation(url: challenge.url)

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
          client.request_challenge_validation(url: challenge.url)
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
          client.request_challenge_validation(url: challenge.url)
        end

        order = client.finalize(url: finalize_url, csr: csr)
        finalized_order = client.order(url: order.url)
        certificate = client.certificate(url: finalized_order.certificate_url)

        expect { OpenSSL::X509::Certificate.new(certificate) }.not_to raise_error
      end

      context 'preferred chain' do
        context 'without alternates link' do
          it 'download a certificate with a preferred match', vcr: { cassette_name: 'certificate_download' } do
            serve_once(challenge.file_content) do
              client.request_challenge_validation(url: challenge.url)
            end

            order = client.finalize(url: finalize_url, csr: csr)
            finalized_order = client.order(url: order.url)
            certificate = client.certificate(url: finalized_order.certificate_url, force_chain: 'Pebble Root CA')

            expect { OpenSSL::X509::Certificate.new(certificate) }.not_to raise_error
          end

          it 'download a certificate and fail preferred match', vcr: { cassette_name: 'certificate_download' } do
            serve_once(challenge.file_content) do
              client.request_challenge_validation(url: challenge.url)
            end

            order = client.finalize(url: finalize_url, csr: csr)
            finalized_order = client.order(url: order.url)
            expect {
              client.certificate(url: finalized_order.certificate_url, force_chain: 'foobar')
            }.to raise_error(Acme::Client::Error::ForcedChainNotFound)
          end
        end

        context 'with alternates link' do
          it 'download a certificate with a preferred match', vcr: { cassette_name: 'certificate_download_with_alternative' } do
            serve_once(challenge.file_content) do
              client.request_challenge_validation(url: challenge.url)
            end

            order = client.finalize(url: finalize_url, csr: csr)
            finalized_order = client.order(url: order.url)
            certificate = client.certificate(url: finalized_order.certificate_url, force_chain: 'Pebble Root CA 769220')

            expect { OpenSSL::X509::Certificate.new(certificate) }.not_to raise_error
            expect(OpenSSL::X509::Certificate.new(certificate).issuer.to_s).to eq('/CN=Pebble Intermediate CA 7c13ed')
          end

          it 'download a certificate and fail preferred match', vcr: { cassette_name: 'certificate_download_with_alternative' } do
            serve_once(challenge.file_content) do
              client.request_challenge_validation(url: challenge.url)
            end

            order = client.finalize(url: finalize_url, csr: csr)
            finalized_order = client.order(url: order.url)
            expect {
              client.certificate(url: finalized_order.certificate_url, force_chain: 'foobar')
            }.to raise_error(Acme::Client::Error::ForcedChainNotFound)
          end
        end
      end
    end

    context 'revoke' do
      let(:finalize_url) { order.finalize_url }
      let(:authorization) { client.authorization(url: order.authorization_urls.first) }
      let(:challenge) { authorization.http01 }
      let(:certificate) do
        serve_once(challenge.file_content) do
          client.request_challenge_validation(url: challenge.url)
        end

        order = client.finalize(url: finalize_url, csr: csr)
        finalized_order = client.order(url: order.url)
        client.certificate(url: finalized_order.certificate_url)
      end

      # TODO: find a way to record fixtures for this, unsupported by pebble at the moment.
      xit 'revoke a PEM string certificate', vcr: { cassette_name: 'revoke_pem_sucess' } do
        serve_once(challenge.file_content) do
          client.request_challenge_validation(url: challenge.url)
        end

        order = client.finalize(url: finalize_url, csr: csr)
        finalized_order = client.order(url: order.url)
        certificate = client.certificate(url: finalized_order.certificate_url)

        client.revoke(certificate: certificate)
      end
    end
  end

  context 'prepare_order_identifiers' do
    it 'accepts a single dns string' do
      expect(unregistered_client.send(:prepare_order_identifiers, 'example.com'))
        .to eq([{ type: 'dns', value: 'example.com' }])
    end

    it 'accepts an array of dns strings' do
      expect(unregistered_client.send(:prepare_order_identifiers, %w(example.com foo.example.com)))
        .to eq([{ type: 'dns', value: 'example.com' }, { type: 'dns', value: 'foo.example.com' }])
    end

    it 'accepts a single identifier hash' do
      expect(unregistered_client.send(:prepare_order_identifiers, type: 'ip', value: '192.168.1.1'))
        .to eq([{ type: 'ip', value: '192.168.1.1' }])
    end

    it 'accepts an array of identifier hashes' do
      identifiers = [{ type: 'ip', value: '192.168.1.1' }, { type: 'dns', value: 'example.com' }]
      expect(unregistered_client.send(:prepare_order_identifiers, identifiers))
        .to eq([{ type: 'ip', value: '192.168.1.1' }, { type: 'dns', value: 'example.com' }])
    end

    it 'accepts a combination of dns strings and identifier hashes' do
      expect(unregistered_client.send(:prepare_order_identifiers, [{ type: 'ip', value: '192.168.1.1' }, 'example.com']))
        .to eq([{ type: 'ip', value: '192.168.1.1' }, { type: 'dns', value: 'example.com' }])
    end
  end
end
