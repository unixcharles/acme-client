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

  def x509_fullchain
    [x509, *x509_chain]
  end

  def fullchain_to_pem
    x509_fullchain.map(&:to_pem).join
  end
end
