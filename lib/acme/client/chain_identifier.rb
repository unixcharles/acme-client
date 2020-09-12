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
      @x509_certificates ||= splitted_pem_certificates.map do |pem|
        OpenSSL::X509::Certificate.new(pem)
      end
    end

    def splitted_pem_certificates
      certificates = []
      certificate_lines = []
      @pem_certificate_chain.each_line do |line|
        certificate_lines << line
        if line.include?('END CERTIFICATE')
          certificates << certificate_lines.join
          certificate_lines = []
        end
      end

      certificates
    end
  end
end