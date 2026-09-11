# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')

require 'acme/client'

RSpec.describe 'Typed errors from order error fields' do
  let(:client) { instance_double(Acme::Client) }

  def build_order(error: nil)
    Acme::Client::Resources::Order.new(
      client,
      url: 'https://example.com/order/1',
      status: error ? 'invalid' : 'ready',
      expires: '2026-03-12T12:00:00Z',
      finalize_url: 'https://example.com/order/1/finalize',
      authorization_urls: ['https://example.com/authz/1'],
      identifiers: [{ 'type' => 'dns', 'value' => 'example.com' }],
      error: error
    )
  end

  describe '#error' do
    it 'is nil when the order has no error' do
      expect(build_order.error).to be_nil
    end

    it 'exposes the raw error hash' do
      raw_error = {
        'type' => 'urn:ietf:params:acme:error:rateLimited',
        'detail' => 'too many certificates already issued for exact set of domains',
        'status' => 429
      }
      expect(build_order(error: raw_error).error).to eq(raw_error)
    end

    it 'round trips through to_h' do
      raw_error = { 'type' => 'urn:ietf:params:acme:error:badCSR', 'detail' => 'CSR public key too small' }
      expect(build_order(error: raw_error).to_h[:error]).to eq(raw_error)
    end
  end

  describe '#typed_error' do
    it 'returns nil when there is no error' do
      expect(build_order.typed_error).to be_nil
    end

    it 'returns a typed RateLimited error' do
      err = build_order(error: {
        'type' => 'urn:ietf:params:acme:error:rateLimited',
        'detail' => 'too many certificates already issued for exact set of domains'
      }).typed_error
      expect(err).to be_a(Acme::Client::Error::RateLimited)
      expect(err.message).to eq('too many certificates already issued for exact set of domains')
      expect(err.problem).to be_a(Acme::Client::Problem)
      expect(err.problem.code).to eq('rateLimited')
    end

    it 'returns a typed BadCSR error' do
      err = build_order(error: {
        'type' => 'urn:ietf:params:acme:error:badCSR',
        'detail' => 'CSR public key too small'
      }).typed_error
      expect(err).to be_a(Acme::Client::Error::BadCSR)
    end

    it 'returns a typed Unauthorized error' do
      err = build_order(error: {
        'type' => 'urn:ietf:params:acme:error:unauthorized',
        'detail' => 'Invalid response from http://example.com/.well-known/acme-challenge/token'
      }).typed_error
      expect(err).to be_a(Acme::Client::Error::Unauthorized)
    end

    it 'falls back to base Error for unknown error types' do
      err = build_order(error: {
        'type' => 'urn:ietf:params:acme:error:unknownFutureThing',
        'detail' => 'Something new happened'
      }).typed_error
      expect(err).to be_a(Acme::Client::Error)
      expect(err.message).to eq('Something new happened')
      expect(err.problem.code).to eq('unknownFutureThing')
      expect(err.problem).not_to be_standard
    end

    it 'uses "Unknown error" when detail is missing' do
      err = build_order(error: { 'type' => 'urn:ietf:params:acme:error:badCSR' }).typed_error
      expect(err).to be_a(Acme::Client::Error::BadCSR)
      expect(err.message).to eq('Unknown error')
    end

    it 'does not alter the raw error hash' do
      raw_error = {
        'type' => 'urn:ietf:params:acme:error:badCSR',
        'detail' => 'CSR public key too small',
        'status' => 400
      }
      order = build_order(error: raw_error)

      order.typed_error

      expect(order.error).to eq(raw_error)
    end
  end
end
