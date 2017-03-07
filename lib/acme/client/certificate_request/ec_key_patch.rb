# Class to handle bug #
class Acme::Client::CertificateRequest::ECKeyPatch < OpenSSL::PKey::EC
  alias private? private_key?
  alias public? public_key?
end
