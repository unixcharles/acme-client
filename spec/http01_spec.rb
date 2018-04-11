# frozen_string_literal: true

require 'spec_helper'

describe Acme::Client::Resources::Challenges::HTTP01 do
  let(:private_key) { generate_private_key }
  let(:client) do
    Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL)
  end
  let(:attributes) do
    { status: 'pending', url: 'https://example.com/foo/bar', token: 'example_token' }
  end
  let(:http01) do
    Acme::Client::Resources::Challenges::HTTP01.new(client, **attributes)
  end

  context 'file_content' do
    it 'match the key_authorization' do
      expect(http01.file_content).to eq(http01.key_authorization)
    end
  end

  context 'filename' do
    it 'returns the filename path for the http challenge' do
      expect(http01.filename).to eq('.well-known/acme-challenge/example_token')
    end
  end
end
