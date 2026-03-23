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
    it 'stores retry_after as an integer number of seconds' do
      error = Acme::Client::Error.new('rate limited', retry_after: '120')
      expect(error.retry_after).to be_a(Integer)
      expect(error.retry_after).to be_within(2).of(120)
    end

    it 'exposes retry_after_time as a parsed Time' do
      now = Time.now
      error = Acme::Client::Error.new('rate limited', retry_after: '120')
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 120)
    end

    it 'returns nil for retry_after and retry_after_time when not provided' do
      error = Acme::Client::Error.new('some error')
      expect(error.retry_after).to be_nil
      expect(error.retry_after_time).to be_nil
    end

    it 'works with no arguments' do
      error = Acme::Client::Error.new
      expect(error.message).to eq('Acme::Client::Error')
      expect(error.retry_after).to be_nil
      expect(error.retry_after_time).to be_nil
    end
  end

  describe Acme::Client::Error::RateLimited do
    it 'stores retry_after as integer seconds (string input)' do
      error = Acme::Client::Error::RateLimited.new('rate limited', '3600')
      expect(error.retry_after).to eq(3600)
    end

    it 'stores retry_after as integer seconds (integer input, backward compatible)' do
      error = Acme::Client::Error::RateLimited.new('rate limited', 60)
      expect(error.retry_after).to eq(60)
    end

    it 'exposes retry_after_time as a Time for string seconds input' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new('rate limited', '60')
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 60)
    end

    it 'exposes retry_after_time as a Time for HTTP-date input' do
      http_date = 'Thu, 06 Mar 2026 14:00:00 GMT'
      error = Acme::Client::Error::RateLimited.new('rate limited', http_date)
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to eq(Time.httpdate(http_date))
    end

    it 'exposes retry_after as seconds-until for HTTP-date input' do
      future = Time.now + 300
      http_date = future.httpdate
      error = Acme::Client::Error::RateLimited.new('rate limited', http_date)
      expect(error.retry_after).to be_a(Integer)
      expect(error.retry_after).to be_within(2).of(300)
    end

    it 'defaults retry_after to 10 when not provided' do
      error = Acme::Client::Error::RateLimited.new
      expect(error.retry_after).to eq(10)
    end

    it 'defaults retry_after to 10 when nil' do
      error = Acme::Client::Error::RateLimited.new('limited', nil)
      expect(error.retry_after).to eq(10)
    end

    it 'defaults retry_after_time to Time.now + 10 when not provided' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 10)
    end

    it 'is a kind of Acme::Client::Error' do
      error = Acme::Client::Error::RateLimited.new('limited', 10)
      expect(error).to be_a(Acme::Client::Error)
    end
  end

  describe Acme::Client::Error::ServerError do
    it 'inherits retry_after support from base Error' do
      error = Acme::Client::Error::ServerError.new('server error', retry_after: '30')
      expect(error.retry_after).to be_a(Integer)
      expect(error.retry_after).to be_within(2).of(30)
    end

    it 'exposes retry_after_time as a parsed Time' do
      now = Time.now
      error = Acme::Client::Error::ServerError.new('server error', retry_after: '30')
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 30)
    end
  end

  describe Acme::Client::Error::ServerInternal do
    it 'inherits retry_after support' do
      now = Time.now
      error = Acme::Client::Error::ServerInternal.new('503', retry_after: '60')
      expect(error.retry_after).to be_within(2).of(60)
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 60)
    end
  end

  describe Acme::Client::Resources::Order do
    let(:client) { instance_double(Acme::Client) }

    it 'exposes retry_after as the raw header string when provided' do
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

    it 'exposes retry_after_time as a parsed Time' do
      now = Time.now
      order = Acme::Client::Resources::Order.new(
        client,
        status: 'processing',
        expires: '2026-03-06T14:00:00Z',
        finalize_url: 'https://example.com/finalize',
        authorization_urls: [],
        identifiers: [],
        retry_after: '30'
      )
      expect(order.retry_after_time).to be_a(Time)
      expect(order.retry_after_time).to be_within(1).of(now + 30)
    end

    it 'defaults retry_after and retry_after_time to nil' do
      order = Acme::Client::Resources::Order.new(
        client,
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        finalize_url: 'https://example.com/finalize',
        authorization_urls: [],
        identifiers: []
      )
      expect(order.retry_after).to be_nil
      expect(order.retry_after_time).to be_nil
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

    it 'exposes retry_after as the raw header string when provided' do
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

    it 'exposes retry_after_time as a parsed Time' do
      now = Time.now
      auth = Acme::Client::Resources::Authorization.new(
        client,
        url: 'https://example.com/authz/1',
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        challenges: [],
        identifier: { 'type' => 'dns', 'value' => 'example.com' },
        retry_after: '15'
      )
      expect(auth.retry_after_time).to be_a(Time)
      expect(auth.retry_after_time).to be_within(1).of(now + 15)
    end

    it 'defaults retry_after and retry_after_time to nil' do
      auth = Acme::Client::Resources::Authorization.new(
        client,
        url: 'https://example.com/authz/1',
        status: 'pending',
        expires: '2026-03-06T14:00:00Z',
        challenges: [],
        identifier: { 'type' => 'dns', 'value' => 'example.com' }
      )
      expect(auth.retry_after).to be_nil
      expect(auth.retry_after_time).to be_nil
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

    it 'exposes retry_after as the raw header string when provided' do
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123',
        retry_after: '5'
      )
      expect(challenge.retry_after).to eq('5')
    end

    it 'exposes retry_after_time as a parsed Time' do
      now = Time.now
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123',
        retry_after: '5'
      )
      expect(challenge.retry_after_time).to be_a(Time)
      expect(challenge.retry_after_time).to be_within(1).of(now + 5)
    end

    it 'defaults retry_after and retry_after_time to nil' do
      challenge = Acme::Client::Resources::Challenges::HTTP01.new(
        client,
        status: 'pending',
        url: 'https://example.com/challenge/1',
        token: 'token123'
      )
      expect(challenge.retry_after).to be_nil
      expect(challenge.retry_after_time).to be_nil
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
    it 'all server error subclasses accept retry_after keyword' do
      Acme::Client::Error::ACME_ERRORS.each_value do |error_class|
        next if error_class == Acme::Client::Error::RateLimited

        error = error_class.new('test', retry_after: '42')
        expect(error.retry_after).to be_within(2).of(42),
          "#{error_class} did not store retry_after correctly"
        expect(error.retry_after_time).to be_a(Time),
          "#{error_class} did not expose retry_after_time correctly"
      end
    end

    it 'RateLimited stores retry_after as integer and retry_after_time as Time' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new('test', '42')
      expect(error.retry_after).to eq(42)
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 42)
    end
  end
end
