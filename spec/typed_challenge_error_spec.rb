# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')

require 'acme/client'

RSpec.describe 'Typed errors from challenge error fields' do
  let(:jwk) { instance_double(Acme::Client::JWK::Base, thumbprint: 'thumb') }
  let(:client) { instance_double(Acme::Client, jwk: jwk) }

  def build_challenge(error: nil)
    Acme::Client::Resources::Challenges::HTTP01.new(
      client,
      status: error ? 'invalid' : 'pending',
      url: 'https://example.com/challenge/1',
      token: 'token123',
      error: error,
      validated: error ? '2026-03-05T12:00:00Z' : nil
    )
  end

  describe '#typed_error' do
    it 'returns nil when there is no error' do
      challenge = build_challenge
      expect(challenge.typed_error).to be_nil
    end

    it 'returns a typed Dns error' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:dns',
        'detail' => 'DNS problem: SERVFAIL looking up A for example.com'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error::Dns)
      expect(err.message).to eq('DNS problem: SERVFAIL looking up A for example.com')
    end

    it 'returns a typed Unauthorized error' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:unauthorized',
        'detail' => 'Invalid response from http://example.com/.well-known/acme-challenge/token'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error::Unauthorized)
    end

    it 'returns a typed Connection error' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:connection',
        'detail' => 'Connection refused'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error::Connection)
    end

    it 'returns a typed Tls error' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:tls',
        'detail' => 'TLS handshake failed'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error::Tls)
    end

    it 'returns a typed IncorrectResponse error' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:incorrectResponse',
        'detail' => 'Response did not match expected key authorization'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error::IncorrectResponse)
    end

    it 'returns a typed Caa error' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:caa',
        'detail' => 'CAA record prevents issuance'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error::Caa)
    end

    it 'falls back to base Error for unknown error types' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:unknownFutureThing',
        'detail' => 'Something new happened'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error)
      expect(err.message).to eq('Something new happened')
    end

    it 'uses "Unknown error" when detail is missing' do
      challenge = build_challenge(error: {
        'type' => 'urn:ietf:params:acme:error:dns'
      })
      err = challenge.typed_error
      expect(err).to be_a(Acme::Client::Error::Dns)
      expect(err.message).to eq('Unknown error')
    end

    it 'does not alter the raw error hash' do
      raw_error = {
        'type' => 'urn:ietf:params:acme:error:dns',
        'detail' => 'SERVFAIL',
        'status' => 400
      }
      challenge = build_challenge(error: raw_error)

      challenge.typed_error

      expect(challenge.error).to eq(raw_error)
    end
  end
end
