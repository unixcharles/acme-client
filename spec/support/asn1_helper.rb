module Asn1Helper
  def asn1_dig(attribute)
    if OpenSSL::VERSION < '2.0.0'
      attribute.value.first.first.value
    else
      attribute.value.value.first.value.first.value
    end
  end
end
