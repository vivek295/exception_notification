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
      unless env.nil?
        request = ActionDispatch::Request.new(env)
        formatted_message = generate_exception_card(request, exception)
      end

      req.body = formatted_message ?
                  formatted_message.to_json :
                  { text: "```#{error_precedence + message}```" }.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.request(req)
    end

    private

    def generate_exception_card(request, exception)
      request_items = {
        url: request.original_url,
        http_method: request.method,
        ip_address: request.remote_ip,
        parameters: request.filtered_parameters.to_s,
        timestamp: Time.current.to_s
      }

      return {
        "@type": "MessageCard",
        "@context": "https://schema.org/extensions",
        "summary": "Exception",
        "themeColor": "0075FF",
        "sections": [
          {
            "startGroup": true,
            "title": "**#{@default_options[:env]} : #{exception.class.to_s}**",
            "activityTitle": "Exception message : #{exception.message}",
            "facts":  request_items.map do |key, value|
                        {name: key, value: value}
                      end
          },
          {
            "startGroup": true,
            "title": "**Backtrace**",
            "activitySubtitle": "#{exception.backtrace.first(10).join("\n\n")}"
          }
        ]
      }
    end
  end

end

