# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')

require 'acme/client'

RSpec.describe 'RFC 7807 subproblems support' do
  let(:raw_subproblems) do
    [
      {
        'type' => 'urn:ietf:params:acme:error:rejectedIdentifier',
        'detail' => 'This CA will not issue for "example.net"',
        'identifier' => { 'type' => 'dns', 'value' => 'example.net' }
      },
      {
        'type' => 'urn:ietf:params:acme:error:caa',
        'detail' => 'CAA record for "example.org" prevents issuance',
        'identifier' => { 'type' => 'dns', 'value' => 'example.org' }
      }
    ]
  end

  describe Acme::Client::Error do
    it 'exposes parsed subproblems when provided' do
      error = Acme::Client::Error.new('multi-identifier failure', subproblems: raw_subproblems)
      expect(error.subproblems.length).to eq(2)
    end

    it 'returns Subproblem structs with type, detail, and identifier' do
      error = Acme::Client::Error.new('failure', subproblems: raw_subproblems)
      sp = error.subproblems.first

      expect(sp).to be_a(Acme::Client::Error::Subproblem)
      expect(sp.type).to eq('urn:ietf:params:acme:error:rejectedIdentifier')
      expect(sp.detail).to eq('This CA will not issue for "example.net"')
      expect(sp.identifier).to eq({ 'type' => 'dns', 'value' => 'example.net' })
    end

    it 'defaults to an empty array when no subproblems' do
      error = Acme::Client::Error.new('simple error')
      expect(error.subproblems).to eq([])
    end

    it 'defaults to an empty array when subproblems is nil' do
      error = Acme::Client::Error.new('simple error', subproblems: nil)
      expect(error.subproblems).to eq([])
    end

    it 'handles non-array subproblems gracefully' do
      error = Acme::Client::Error.new('bad data', subproblems: 'not an array')
      expect(error.subproblems).to eq([])
    end

    it 'works with no arguments' do
      error = Acme::Client::Error.new
      expect(error.subproblems).to eq([])
    end
  end

  describe Acme::Client::Error::Subproblem do
    it 'supports keyword initialization' do
      sp = Acme::Client::Error::Subproblem.new(
        type: 'urn:ietf:params:acme:error:dns',
        detail: 'DNS lookup failed',
        identifier: { 'type' => 'dns', 'value' => 'example.com' }
      )

      expect(sp.type).to eq('urn:ietf:params:acme:error:dns')
      expect(sp.detail).to eq('DNS lookup failed')
      expect(sp.identifier).to eq({ 'type' => 'dns', 'value' => 'example.com' })
    end

    it 'supports to_h' do
      sp = Acme::Client::Error::Subproblem.new(
        type: 'urn:ietf:params:acme:error:dns',
        detail: 'DNS lookup failed',
        identifier: { 'type' => 'dns', 'value' => 'example.com' }
      )

      expect(sp.to_h).to eq({
        type: 'urn:ietf:params:acme:error:dns',
        detail: 'DNS lookup failed',
        identifier: { 'type' => 'dns', 'value' => 'example.com' }
      })
    end

    it 'handles nil fields' do
      sp = Acme::Client::Error::Subproblem.new(
        type: 'urn:ietf:params:acme:error:dns',
        detail: nil,
        identifier: nil
      )

      expect(sp.type).to eq('urn:ietf:params:acme:error:dns')
      expect(sp.detail).to be_nil
      expect(sp.identifier).to be_nil
    end
  end

  describe 'subproblems on error subclasses' do
    it 'works on Malformed errors (common multi-identifier parent)' do
      error = Acme::Client::Error::Malformed.new(
        'Some of the identifiers requested were rejected',
        subproblems: raw_subproblems
      )
      expect(error.subproblems.length).to eq(2)
      expect(error.subproblems.first.type).to eq('urn:ietf:params:acme:error:rejectedIdentifier')
    end

    it 'works on Unauthorized errors' do
      error = Acme::Client::Error::Unauthorized.new('unauthorized', subproblems: raw_subproblems)
      expect(error.subproblems.length).to eq(2)
    end

    it 'works on RateLimited with positional args preserved' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new('rate limited', 60, subproblems: raw_subproblems)
      expect(error.retry_after).to eq(60)
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 60)
      expect(error.subproblems.length).to eq(2)
    end

    it 'works on RateLimited with defaults' do
      now = Time.now
      error = Acme::Client::Error::RateLimited.new
      expect(error.retry_after).to eq(10)
      expect(error.retry_after_time).to be_a(Time)
      expect(error.retry_after_time).to be_within(1).of(now + 10)
      expect(error.subproblems).to eq([])
    end

    it 'all ACME_ERRORS subclasses accept subproblems keyword' do
      Acme::Client::Error::ACME_ERRORS.each_value do |error_class|
        next if error_class == Acme::Client::Error::RateLimited

        error = error_class.new('test', subproblems: raw_subproblems)
        expect(error.subproblems.length).to eq(2),
          "#{error_class} did not accept subproblems correctly"
      end
    end
  end

  describe 'single subproblem' do
    it 'handles a response with one subproblem' do
      error = Acme::Client::Error::Malformed.new(
        'identifier rejected',
        subproblems: [raw_subproblems.first]
      )
      expect(error.subproblems.length).to eq(1)
      expect(error.subproblems.first.detail).to eq('This CA will not issue for "example.net"')
    end
  end
end
