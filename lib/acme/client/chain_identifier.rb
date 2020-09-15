class Acme::Client
  class ChainIdentifier
    def initialize(pem_certificate_chain)
      @pem_certificate_chain = pem_certificate_chain
    end

    def match_name?(name)
      issuers.any? do |issuer|
        issuer.include?(name)
      end
    end

    private

    def issuers
      x509_certificates.map(&:issuer).map(&:to_s)
    end

    def x509_certificates
      @x509_certificates ||= splitted_pem_certificates.map { |pem| OpenSSL::X509::Certificate.new(pem) }
    end

    def splitted_pem_certificates
      @pem_certificate_chain.each_line.slice_after(/END CERTIFICATE/).map(&:join)
    end
  end
end
