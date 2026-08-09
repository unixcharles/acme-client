# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')

require 'acme/client'

RSpec.describe Acme::Client::Problem do
  let(:raw_problem) do
    {
      'type' => 'urn:ietf:params:acme:error:unauthorized',
      'title' => 'Unauthorized',
      'detail' => 'The client lacks sufficient authorization',
      'status' => 403,
      'instance' => 'https://ca.example.test/problems/1',
      'identifier' => { 'type' => 'dns', 'value' => 'example.test' },
      'extra' => 'kept'
    }
  end

  describe '.from' do
    it 'wraps hashes' do
      problem = described_class.from(raw_problem)
      expect(problem).to be_a(described_class)
      expect(problem.to_h).to eq(raw_problem)
    end

    it 'returns existing problems unchanged' do
      problem = described_class.new(raw_problem)
      expect(described_class.from(problem)).to equal(problem)
    end

    it 'returns nil for nil' do
      expect(described_class.from(nil)).to be_nil
    end
  end

  describe 'problem document fields' do
    subject(:problem) { described_class.new(raw_problem) }

    it 'exposes RFC 7807 fields' do
      expect(problem.type).to eq('urn:ietf:params:acme:error:unauthorized')
      expect(problem.title).to eq('Unauthorized')
      expect(problem.detail).to eq('The client lacks sufficient authorization')
      expect(problem.status).to eq(403)
      expect(problem.instance).to eq('https://ca.example.test/problems/1')
    end

    it 'exposes ACME extension fields' do
      expect(problem.identifier).to eq({ 'type' => 'dns', 'value' => 'example.test' })
    end

    it 'keeps the raw problem document for extension fields' do
      expect(problem.raw['extra']).to eq('kept')
    end
  end

  describe '#code' do
    it 'strips the ACME error prefix for registered ACME problem types' do
      problem = described_class.new(raw_problem)
      expect(problem.code).to eq('unauthorized')
    end

    it 'returns nil for non-ACME problem types' do
      problem = described_class.new('type' => 'https://ca.example.test/errors/account-blocked')
      expect(problem.code).to be_nil
    end
  end

  describe '#registered?' do
    it 'returns true for IANA registered ACME error types' do
      problem = described_class.new('type' => 'urn:ietf:params:acme:error:onionCAARequired')
      expect(problem).to be_registered
      expect(problem).to be_standard
    end

    it 'returns false for unknown ACME error types' do
      problem = described_class.new('type' => 'urn:ietf:params:acme:error:futureError')
      expect(problem).not_to be_registered
      expect(problem).not_to be_standard
    end
  end

  describe '#description' do
    it 'returns the registered description for known ACME error types' do
      problem = described_class.new('type' => 'urn:ietf:params:acme:error:rateLimited')
      expect(problem.description).to eq('The request exceeds a rate limit')
    end
  end

  describe '#matches?' do
    subject(:problem) { described_class.new(raw_problem) }

    it 'matches full URNs' do
      expect(problem.matches?('urn:ietf:params:acme:error:unauthorized')).to be(true)
    end

    it 'matches short codes' do
      expect(problem.matches?('unauthorized')).to be(true)
    end

    it 'does not match other problem types' do
      expect(problem.matches?('rateLimited')).to be(false)
    end
  end

  describe '#subproblems' do
    it 'parses subproblems as problem objects' do
      problem = described_class.new(
        'type' => 'urn:ietf:params:acme:error:compound',
        'subproblems' => [
          {
            'type' => 'urn:ietf:params:acme:error:caa',
            'detail' => 'CAA forbids issuance',
            'identifier' => { 'type' => 'dns', 'value' => 'example.test' }
          }
        ]
      )

      expect(problem.subproblems.length).to eq(1)
      expect(problem.subproblems.first).to be_a(described_class)
      expect(problem.subproblems.first.code).to eq('caa')
      expect(problem.subproblems.first.identifier).to eq({ 'type' => 'dns', 'value' => 'example.test' })
    end

    it 'returns an empty array when subproblems is missing' do
      expect(described_class.new(raw_problem).subproblems).to eq([])
    end
  end

  describe '#message' do
    it 'prefers detail over title and type' do
      problem = described_class.new(raw_problem)
      expect(problem.message).to eq('The client lacks sufficient authorization')
    end

    it 'falls back to title and type' do
      expect(described_class.new('title' => 'A title', 'type' => 'about:blank').message).to eq('A title')
      expect(described_class.new('type' => 'about:blank').message).to eq('about:blank')
    end
  end
end
