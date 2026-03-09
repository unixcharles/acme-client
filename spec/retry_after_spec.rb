# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')

require 'acme/client'

RSpec.describe 'Retry-After support' do
  describe Acme::Client::Util do
    describe '.parse_retry_after' do
      it 'parses integer seconds into a Time' do
        now = Time.now
        result = Acme::Client::Util.parse_retry_after('120')
        expect(result).to be_a(Time)
        expect(result).to be_within(1).of(now + 120)
      end

      it 'parses an HTTP-date into a Time' do
        http_date = 'Thu, 06 Mar 2026 14:00:00 GMT'
        result = Acme::Client::Util.parse_retry_after(http_date)
        expect(result).to be_a(Time)
        expect(result).to eq(Time.httpdate(http_date))
      end

      it 'handles numeric input via to_s' do
        now = Time.now
        result = Acme::Client::Util.parse_retry_after(60)
        expect(result).to be_a(Time)
        expect(result).to be_within(1).of(now + 60)
      end

      it 'returns nil for nil' do
        expect(Acme::Client::Util.parse_retry_after(nil)).to be_nil
      end

      it 'returns nil for unparseable values' do
        expect(Acme::Client::Util.parse_retry_after('garbage')).to be_nil
      end
    end
  end

  describe Acme::Client::Error do
    it 'stores retry_after as a Time when provided' do
      time = Time.now + 120
      error = Acme::Client::Error.new('rate limited', retry_after: time)
      expect(error.retry_after).to eq(time)
    end

    it 'returns nil when retry_after is not provided' do
      error = Acme::Client::Error.new('some error')
      expect(error.retry_after).to be_nil
    end

    it 'works with no arguments' do
      error = Acme::Client::Error.new
      expect(error.message).to eq('Acme::Client::Error')
      expect(error.retry_after).to be_nil
    end
  end

  describe Acme::Client::Error::RateLimited do
    it 'accepts a Time as retry_after (from middleware)' do
      time = Time.now + 60
      error = Acme::Client::Error::RateLimited.new('rate limited', time)
      expect(error.retry_after).to eq(time)
      expect(error.message).to eq('rate limited')
    end

    it 'accepts integer seconds as retry_after (backward compatible)' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new('rate limited', 60)
      expect(error.retry_after).to be_a(Time)
      expect(error.retry_after).to be_within(1).of(now + 60)
    end

    it 'accepts string seconds as retry_after (backward compatible)' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new('limited', '300')
      expect(error.retry_after).to be_a(Time)
      expect(error.retry_after).to be_within(1).of(now + 300)
    end

    it 'defaults to Time.now + 10 when retry_after is not provided' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new
      expect(error.retry_after).to be_a(Time)
      expect(error.retry_after).to be_within(1).of(now + 10)
    end

    it 'defaults to Time.now + 10 when retry_after is nil' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new('limited', nil)
      expect(error.retry_after).to be_a(Time)
      expect(error.retry_after).to be_within(1).of(now + 10)
    end

    it 'is a kind of Acme::Client::Error' do
      error = Acme::Client::Error::RateLimited.new('limited', 10)
      expect(error).to be_a(Acme::Client::Error)
      expect(error.retry_after).to be_a(Time)
    end
  end

  describe Acme::Client::Error::ServerError do
    it 'inherits retry_after support from base Error' do
      time = Time.now + 30
      error = Acme::Client::Error::ServerError.new('server error', retry_after: time)
      expect(error.retry_after).to eq(time)
    end
  end

  describe Acme::Client::Error::ServerInternal do
    it 'inherits retry_after support' do
      time = Time.now + 60
      error = Acme::Client::Error::ServerInternal.new('503', retry_after: time)
      expect(error.retry_after).to eq(time)
    end
  end

  describe Acme::Client::Resources::Order do
    let(:client) { instance_double(Acme::Client) }

    it 'exposes retry_after as a Time when provided' do
      time = Time.now + 30
      order = Acme::Client::Resources::Order.new(
        client,
        status: 'processing',
        expires: '2026-03-06T14:00:00Z',
        finalize_url: 'https://example.com/finalize',
        authorization_urls: [],
        identifiers: [],
        retry_after: time
      )
      expect(order.retry_after).to eq(time)
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
      time = Time.now + 10
      order = Acme::Client::Resources::Order.new(
        client,
        status: 'processing',
        expires: '2026-03-06T14:00:00Z',
        finalize_url: 'https://example.com/finalize',
        authorization_urls: [],
        identifiers: [],
        retry_after: time
      )
      expect(order.to_h[:retry_after]).to eq(time)
    end
  end

  describe Acme::Client::Resources::Authorization do
    let(:client) { instance_double(Acme::Client) }

    it 'exposes retry_after as a Time when provided' do
      time = Time.now + 15
      auth = Acme::Client::Resources::Authorization.new(
        client,
        url: 'https://example.com/authz/1',
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        challenges: [],
        identifier: { 'type' => 'dns', 'value' => 'example.com' },
        retry_after: time
      )
      expect(auth.retry_after).to eq(time)
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
      time = Time.now + 15
      auth = Acme::Client::Resources::Authorization.new(
        client,
        url: 'https://example.com/authz/1',
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        challenges: [],
        identifier: { 'type' => 'dns', 'value' => 'example.com' },
        retry_after: time
      )
      expect(auth.to_h[:retry_after]).to eq(time)
    end
  end

  describe Acme::Client::Resources::Challenges::Base do
    let(:client) { instance_double(Acme::Client, jwk: instance_double(Acme::Client::JWK::Base, thumbprint: 'thumb')) }

    it 'exposes retry_after as a Time when provided' do
      time = Time.now + 5
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123',
        retry_after: time
      )
      expect(challenge.retry_after).to eq(time)
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
      time = Time.now + 5
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123',
        retry_after: time
      )
      expect(challenge.to_h[:retry_after]).to eq(time)
    end
  end

  describe 'AcmeMiddleware#raise_on_error!' do
    it 'all server error subclasses accept retry_after keyword' do
      time = Time.now + 42
      Acme::Client::Error::ACME_ERRORS.each_value do |error_class|
        next if error_class == Acme::Client::Error::RateLimited

        error = error_class.new('test', retry_after: time)
        expect(error.retry_after).to eq(time),
          "#{error_class} did not store retry_after correctly"
      end
    end

    it 'RateLimited accepts retry_after as positional arg (backward compatible)' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new('test', '42')
      expect(error.retry_after).to be_a(Time)
      expect(error.retry_after).to be_within(1).of(now + 42)
    end
  end
end
