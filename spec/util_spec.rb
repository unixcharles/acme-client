require 'spec_helper'

describe Acme::Client::JWK do
  context '#decode_link_headers' do
    let(:example) do
      '<uri1>; rel="up", <uri2>; rel="alt", <uri3>; rel="alt"'
    end

    it 'extract link value and in a hash with rel as they key' do
      links = Acme::Client::Util.decode_link_headers(example)
      expect(links).to be_a(Hash)
      expect(links['up']).to eq(['uri1'])
      expect(links['alt'].sort).to eq(%w(uri2 uri3).sort)
    end
  end
end
