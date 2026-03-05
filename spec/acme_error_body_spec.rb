# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, '../lib')

require 'acme/client'

RSpec.describe 'Full problem document (acme_error_body) support' do
  let(:problem_document) do
    {
      'type' => 'urn:ietf:params:acme:error:rateLimited',
      'detail' => 'too many certificates already issued for "example.com"',
      'status' => 429,
      'instance' => 'https://ca.example.com/acme/error/abc123'
    }
  end

  describe Acme::Client::Error do
    it 'exposes the full problem document when provided' do
      error = Acme::Client::Error.new('rate limited', acme_error_body: problem_document)
      expect(error.acme_error_body).to eq(problem_document)
    end

    it 'defaults to nil when not provided' do
      error = Acme::Client::Error.new('some error')
      expect(error.acme_error_body).to be_nil
    end

    it 'works with no arguments' do
      error = Acme::Client::Error.new
      expect(error.acme_error_body).to be_nil
    end

    it 'preserves CA-specific extension fields' do
      body = problem_document.merge('boulder-requester' => '12345')
      error = Acme::Client::Error.new('error', acme_error_body: body)
      expect(error.acme_error_body['boulder-requester']).to eq('12345')
    end

    it 'provides access to status from the problem document' do
      error = Acme::Client::Error.new('error', acme_error_body: problem_document)
      expect(error.acme_error_body['status']).to eq(429)
    end

    it 'provides access to instance URL from the problem document' do
      error = Acme::Client::Error.new('error', acme_error_body: problem_document)
      expect(error.acme_error_body['instance']).to eq('https://ca.example.com/acme/error/abc123')
    end
  end

  describe 'acme_error_body on error subclasses' do
    it 'works on ServerError subclasses' do
      error = Acme::Client::Error::Unauthorized.new('unauthorized', acme_error_body: problem_document)
      expect(error.acme_error_body).to eq(problem_document)
    end

    it 'works on RateLimited with positional args preserved' do
      error = Acme::Client::Error::RateLimited.new('rate limited', 60, acme_error_body: problem_document)
      expect(error.retry_after).to eq(60)
      expect(error.acme_error_body).to eq(problem_document)
    end

    it 'works on RateLimited with defaults' do
      error = Acme::Client::Error::RateLimited.new
      expect(error.retry_after).to eq(10)
      expect(error.acme_error_body).to be_nil
    end

    it 'all ACME_ERRORS subclasses accept acme_error_body keyword' do
      Acme::Client::Error::ACME_ERRORS.each_value do |error_class|
        next if error_class == Acme::Client::Error::RateLimited

        error = error_class.new('test', acme_error_body: problem_document)
        expect(error.acme_error_body).to eq(problem_document),
          "#{error_class} did not accept acme_error_body correctly"
      end
    end
  end

  describe 'problem documents with subproblems field' do
    it 'preserves subproblems in the raw body for downstream parsing' do
      body = problem_document.merge(
        'subproblems' => [
          {
            'type' => 'urn:ietf:params:acme:error:rejectedIdentifier',
            'detail' => 'CA will not issue for "example.net"',
            'identifier' => { 'type' => 'dns', 'value' => 'example.net' }
          }
        ]
      )
      error = Acme::Client::Error::Malformed.new('rejected', acme_error_body: body)
      expect(error.acme_error_body['subproblems'].length).to eq(1)
      expect(error.acme_error_body['subproblems'].first['identifier']['value']).to eq('example.net')
    end
  end
end
