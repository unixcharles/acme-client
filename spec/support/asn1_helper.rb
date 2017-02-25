module Asn1Helper
  def asn1_dig(obj)
    if obj.respond_to?(:first) && obj.first.is_a?(Enumerable)
      asn1_dig obj.first
    elsif obj.respond_to?(:value) && obj.value.is_a?(Enumerable)
      asn1_dig obj.value
    else
      obj
    end
  end
end
