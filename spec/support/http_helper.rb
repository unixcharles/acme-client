require 'webrick'

module HttpHelper
  def serve_once(body)
    return yield unless VCR.real_http_connections_allowed?

    dev_null = Logger.new(StringIO.new)
    server = WEBrick::HTTPServer.new(Port: 5002, Logger: dev_null, AccessLog: dev_null)

    begin
      thread = Thread.new do
        server.mount_proc('/') do |_, response|
          response.body = body
        end
        server.start
      end

      yield
      sleep(1)
    ensure
      server.shutdown
      thread.join(5)
    end
  end
end
