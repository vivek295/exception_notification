module ExceptionNotifier
  class TeamWebhookNotifier < BaseNotifier

    def initialize(options)
      super
      @default_options = options
    end

    # very basic team webhook notifier
    def call(exception, options={})
      env = options[:env]

      options = options.reverse_merge(@default_options)
      url = options.delete(:url)
      http_method = :post

      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      message = "[#{env} Error]: " + (exception.is_a?(String) ? exception : exception.backtrace.join("\n"))
      req.body = { text: message }.to_json
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.request(req)
    end
  end

end

