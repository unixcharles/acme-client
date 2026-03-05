# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')

require 'acme/client'

RSpec.describe 'Retry-After support' do
  describe Acme::Client::Error do
    it 'accepts retry_after as an integer' do
      error = Acme::Client::Error.new('rate limited', retry_after: 120)
      expect(error.retry_after).to eq(120)
    end

    it 'parses retry_after from an integer string' do
      error = Acme::Client::Error.new('rate limited', retry_after: '120')
      expect(error.retry_after).to eq(120)
    end

    it 'parses retry_after from an HTTP-date string' do
      http_date = 'Thu, 06 Mar 2026 14:00:00 GMT'
      error = Acme::Client::Error.new('rate limited', retry_after: http_date)
      expect(error.retry_after).to be_a(Time)
      expect(error.retry_after).to eq(Time.httpdate(http_date))
    end

    it 'returns nil for nil retry_after' do
      error = Acme::Client::Error.new('some error')
      expect(error.retry_after).to be_nil
    end

    it 'returns nil for unparseable retry_after' do
      error = Acme::Client::Error.new('some error', retry_after: 'garbage')
      expect(error.retry_after).to be_nil
    end

    it 'works with no arguments' do
      error = Acme::Client::Error.new
      expect(error.message).to eq('Acme::Client::Error')
      expect(error.retry_after).to be_nil
    end
  end

  describe Acme::Client::Error::RateLimited do
    it 'accepts retry_after as a positional argument (backward compatible)' do
      error = Acme::Client::Error::RateLimited.new('rate limited', 60)
      expect(error.retry_after).to eq(60)
      expect(error.message).to eq('rate limited')
    end

    it 'defaults to 10 when retry_after is not provided' do
      error = Acme::Client::Error::RateLimited.new
      expect(error.message).to eq('Error message: urn:ietf:params:acme:error:rateLimited')
      expect(error.retry_after).to eq(10)
    end

    it 'defaults to 10 when retry_after is nil' do
      error = Acme::Client::Error::RateLimited.new('limited', nil)
      expect(error.retry_after).to eq(10)
    end

    it 'parses string retry_after' do
      error = Acme::Client::Error::RateLimited.new('limited', '300')
      expect(error.retry_after).to eq(300)
    end

    it 'is a kind of Acme::Client::Error' do
      error = Acme::Client::Error::RateLimited.new('limited', 10)
      expect(error).to be_a(Acme::Client::Error)
      expect(error.retry_after).to eq(10)
    end
  end

  describe Acme::Client::Error::ServerError do
    it 'inherits retry_after support from base Error' do
      error = Acme::Client::Error::ServerError.new('server error', retry_after: 30)
      expect(error.retry_after).to eq(30)
    end
  end

  describe Acme::Client::Error::ServerInternal do
    it 'inherits retry_after support' do
      error = Acme::Client::Error::ServerInternal.new('503', retry_after: '60')
      expect(error.retry_after).to eq(60)
    end
  end

  describe Acme::Client::Resources::Order do
    let(:client) { instance_double(Acme::Client) }

    it 'exposes retry_after when provided' do
      order = Acme::Client::Resources::Order.new(
        client,
        status: 'processing',
        expires: '2026-03-06T14:00:00Z',
        finalize_url: 'https://example.com/finalize',
        authorization_urls: [],
        identifiers: [],
        retry_after: '30'
      )
      expect(order.retry_after).to eq('30')
    end

    it 'defaults retry_after to nil' do
      order = Acme::Client::Resources::Order.new(
        client,
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        finalize_url: 'https://example.com/finalize',
        authorization_urls: [],
        identifiers: []
      )
      expect(order.retry_after).to be_nil
    end

    it 'includes retry_after in to_h' do
      order = Acme::Client::Resources::Order.new(
        client,
        status: 'processing',
        expires: '2026-03-06T14:00:00Z',
        finalize_url: 'https://example.com/finalize',
        authorization_urls: [],
        identifiers: [],
        retry_after: '10'
      )
      expect(order.to_h[:retry_after]).to eq('10')
    end
  end

  describe Acme::Client::Resources::Authorization do
    let(:client) { instance_double(Acme::Client) }

    it 'exposes retry_after when provided' do
      auth = Acme::Client::Resources::Authorization.new(
        client,
        url: 'https://example.com/authz/1',
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        challenges: [],
        identifier: { 'type' => 'dns', 'value' => 'example.com' },
        retry_after: '15'
      )
      expect(auth.retry_after).to eq('15')
    end

    it 'defaults retry_after to nil' do
      auth = Acme::Client::Resources::Authorization.new(
        client,
        url: 'https://example.com/authz/1',
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        challenges: [],
        identifier: { 'type' => 'dns', 'value' => 'example.com' }
      )
      expect(auth.retry_after).to be_nil
    end

    it 'includes retry_after in to_h' do
      auth = Acme::Client::Resources::Authorization.new(
        client,
        url: 'https://example.com/authz/1',
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        challenges: [],
        identifier: { 'type' => 'dns', 'value' => 'example.com' },
        retry_after: '15'
      )
      expect(auth.to_h[:retry_after]).to eq('15')
    end
  end

  describe Acme::Client::Resources::Challenges::Base do
    let(:client) { instance_double(Acme::Client, jwk: instance_double(Acme::Client::JWK::Base, thumbprint: 'thumb')) }

    it 'exposes retry_after when provided' do
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123',
        retry_after: '5'
      )
      expect(challenge.retry_after).to eq('5')
    end

    it 'defaults retry_after to nil' do
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123'
      )
      expect(challenge.retry_after).to be_nil
    end

    it 'includes retry_after in to_h' do
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123',
        retry_after: '5'
      )
      expect(challenge.to_h[:retry_after]).to eq('5')
    end
  end

  describe 'AcmeMiddleware#raise_on_error!' do
    # Test that the middleware passes Retry-After to error constructors
    # by testing the integration through the error classes
    it 'all server error subclasses accept retry_after keyword' do
      Acme::Client::Error::ACME_ERRORS.each_value do |error_class|
        next if error_class == Acme::Client::Error::RateLimited # uses positional arg

        error = error_class.new('test', retry_after: '42')
        expect(error.retry_after).to eq(42),
          "#{error_class} did not parse retry_after correctly"
      end
    end

    it 'RateLimited accepts retry_after as positional arg (backward compatible)' do
      error = Acme::Client::Error::RateLimited.new('test', '42')
      expect(error.retry_after).to eq(42)
    end
  end
end
