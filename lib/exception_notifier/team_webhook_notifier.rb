module ExceptionNotifier
  class TeamWebhookNotifier < BaseNotifier

    def initialize(options)
      super
      @default_options = options
    end

    # very basic team webhook notifier
    def call(exception, options={})
      options = options.reverse_merge(@default_options)
      error_precedence = "[#{options[:env]} Error]: "

      url = options.delete(:url)
      http_method = :post

      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')

      message = if exception.is_a?(String)
                  exception
                elsif options[:simplified]
                  exception.backtrace.reject{|l| l =~ %r|\A[^:]*/gems/|}.join("\n")
                else
                  exception.backtrace.join("\n")
                end

      req.body = { text: "```#{error_precedence + message}```" }.to_json
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.request(req)
    end
  end

end

