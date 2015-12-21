require 'socket'

module TlsHelper
  def listen_tls(certificate, private_key)
    return yield unless VCR.real_http_connections_allowed?

    server = TCPServer.new(5001)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.cert = certificate
    ssl_context.key = private_key
    ssl_server = OpenSSL::SSL::SSLServer.new(server, ssl_context)

    begin
      thread = Thread.new do
        client = ssl_server.accept
        while line = client.gets
          # no-op
        end
      end

      yield
    ensure
      ssl_server.close
      thread.join(5)
    end
  end
end
