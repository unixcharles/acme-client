# frozen_string_literal: true

require 'spec_helper'

describe Acme::Client::Resources::Challenges::DNS01 do
  let(:private_key) { generate_private_key }
  let(:client) do
    Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL)
  end
  let(:attributes) do
    { status: 'pending', url: 'https://example.com/foo/bar', token: 'example_token' }
  end
  let(:dns01) do
    Acme::Client::Resources::Challenges::DNS01.new(client, **attributes)
  end

  it { expect(dns01.record_name).to eq('_acme-challenge') }
  it { expect(dns01.record_type).to eq('TXT') }
  it { expect(dns01.record_content).to be_a(String) }
end
