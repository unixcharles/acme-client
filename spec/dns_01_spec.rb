require 'spec_helper'

describe Acme::Client::Resources::Challenges::DNS01 do
  let(:private_key) { generate_private_key }
  let(:client) do
    client = Acme::Client.new(private_key: private_key, directory: $directory_url)
    client
  end

  let(:dns01) do
    Acme::Client::Resources::Challenges::DNS01.new(
      client,
      url: 'https://0.0.0.0:14000/chalZ/pvR3znNWodojN2UaQMHXwgS3wgChw8UkDkqfUUw2t9g',
      token: 'teKdptO0MN73jZL9MtC7tqWr80tyInBIo1P1uqQNHuw',
      status: 'pending',
    )
  end

  it 'returns the correct record metadata' do
    expect(dns01.record_name).to eq '_acme-challenge'
    expect(dns01.record_type).to eq 'TXT'
    expect(dns01.record_content).to be_a(String)
  end

end
