class Acme::Certificate
  extend Forwardable

  attr_reader :x509, :x509_chain

  def_delegators :x509, :to_pem, :to_der

  def initialize(certificate, chain)
    @x509 = certificate
    @x509_chain = chain
  end

  def chain_to_pem
    x509_chain.map(&:to_pem).join
  end

  def fullchain_to_pem
    [*x509_chain, x509].map(&:to_pem).join
  end
end
