# frozen_string_literal: true

require 'spec_helper'

require 'csv'
require 'net/http'
require 'uri'

# This spec depends on IANA's live registry and is intentionally excluded from
# the default `rake spec` run (see spec_helper.rb). It runs on its own via
# `rake spec_iana_registry` / the scheduled "IANA Registry Check" workflow, so
# that a newly registered ACME error doesn't fail the whole test suite.
RSpec.describe Acme::Client::Problem, :iana_registry do
  describe 'IANA registered ACME error types' do
    let(:iana_registry) { fetch_iana_acme_error_type_registry }

    def fetch_iana_acme_error_type_registry
      uri = URI('https://www.iana.org/assignments/acme/acme-error-types.csv')

      response = with_real_http do
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
          http.get(uri.request_uri)
        end
      end

      expect(response).to be_a(Net::HTTPSuccess)

      CSV.parse(response.body, headers: true).each_with_object({}) do |row, registry|
        registry[row['Type']] = normalize_iana_description(row['Description'])
      end
    end

    def with_real_http
      return VCR.turned_off { with_webmock_net_connect { yield } } if defined?(VCR)

      with_webmock_net_connect { yield }
    end

    def with_webmock_net_connect
      return yield unless defined?(WebMock)

      webmock_enabled = true
      WebMock.allow_net_connect!
      yield
    ensure
      WebMock.disable_net_connect! if webmock_enabled
    end

    def normalize_iana_description(description)
      description.to_s.gsub(/\s+/, ' ').strip
    end

    it 'has problem descriptions for each mapped ACME error class' do
      Acme::Client::Error::ACME_ERRORS.each_key do |type|
        problem = described_class.new('type' => type)
        expect(problem.description).not_to be_nil
      end
    end

    it 'matches the live IANA ACME error type registry' do
      registered_descriptions = described_class::REGISTERED_ERROR_TYPE_DESCRIPTIONS
      registered_types = registered_descriptions.keys
      iana_types = iana_registry.keys
      missing_types = iana_types - registered_types
      extra_types = registered_types - iana_types
      mismatched_descriptions = iana_registry.each_with_object({}) do |(type, description), mismatches|
        next unless registered_descriptions.key?(type)
        next if normalize_iana_description(registered_descriptions[type]) == description

        mismatches[type] = {
          iana: description,
          registered: normalize_iana_description(registered_descriptions[type])
        }
      end
      missing_error_classes = iana_types.map { |type| "#{described_class::ERROR_PREFIX}#{type}" } - Acme::Client::Error::ACME_ERRORS.keys

      expect(missing_types).to be_empty, "missing registered ACME problem descriptions: #{missing_types.join(', ')}"
      expect(extra_types).to be_empty, "extra registered ACME problem descriptions: #{extra_types.join(', ')}"
      expect(mismatched_descriptions).to be_empty, "mismatched IANA ACME problem descriptions: #{mismatched_descriptions.inspect}"
      expect(missing_error_classes).to be_empty, "missing ACME error classes: #{missing_error_classes.join(', ')}"
    end

    it 'maps registered extension error types to typed errors' do
      expect(Acme::Client::Error::ACME_ERRORS['urn:ietf:params:acme:error:compound']).to eq(Acme::Client::Error::Compound)
      expect(Acme::Client::Error::ACME_ERRORS['urn:ietf:params:acme:error:autoRenewalCanceled']).to eq(Acme::Client::Error::AutoRenewalCanceled)
      expect(Acme::Client::Error::ACME_ERRORS['urn:ietf:params:acme:error:unknownDelegation']).to eq(Acme::Client::Error::UnknownDelegation)
      expect(Acme::Client::Error::ACME_ERRORS['urn:ietf:params:acme:error:onionCAARequired']).to eq(Acme::Client::Error::OnionCAARequired)
    end
  end
end
