# frozen_string_literal: true

class Acme::Client::Resources::Directory
  DIRECTORY_RESOURCES = {
    new_nonce: 'newNonce',
    new_account: 'newAccount',
    new_order: 'newOrder',
    new_authz: 'newAuthz',
    revoke_certificate: 'revokeCert',
    key_change: 'keyChange',
    renewal_info: 'renewalInfo'
  }

  DIRECTORY_META = {
    terms_of_service: 'termsOfService',
    website: 'website',
    caa_identities: 'caaIdentities',
    external_account_required: 'externalAccountRequired',
    profiles: 'profiles'
  }

  def initialize(client, **arguments)
    @client = client
    assign_attributes(**arguments)
  end

  def endpoint_for(key)
    @directory.fetch(key) do |missing_key|
      raise Acme::Client::Error::UnsupportedOperation,
        "Directory at #{@url} does not include `#{missing_key}`"
    end
  end

  def terms_of_service
    meta[DIRECTORY_META[:terms_of_service]]
  end

  def website
    meta[DIRECTORY_META[:website]]
  end

  def caa_identities
    meta[DIRECTORY_META[:caa_identities]]
  end

  def external_account_required
    meta[DIRECTORY_META[:external_account_required]]
  end

  def profiles
    meta[DIRECTORY_META[:profiles]]
  end

  def meta
    @directory[:meta]
  end

  private

  def assign_attributes(directory:)
    @directory = {}
    @directory[:meta] = directory.delete('meta')
    DIRECTORY_RESOURCES.each do |key, entry|
      @directory[key] = URI(directory[entry]) if directory[entry]
    end
  end
end
