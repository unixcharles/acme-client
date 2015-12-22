require 'socket'

module TlsHelper
  def listen_tls(certificate, private_key)
    return yield unless VCR.real_http_connections_allowed?
    server = tls_server(certificate, private_key)

    begin
      thread = Thread.new do
        server.accept
      end

      yield
    ensure
      server.close
      thread.join(5)
    end
  end

  def tls_server(certificate, private_key)
    server = TCPServer.new(5001)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.cert = certificate
    ssl_context.key = private_key
    OpenSSL::SSL::SSLServer.new(server, ssl_context)
  end
end
