require "rack/request"
require "rack/response"


module Lanyon

  # Rack application that serves the Jekyll site.
  #
  # Not to be instantiated directly, use Lanyon.application instead.
  class Application

    attr_reader :router

    def initialize(router)
      @router = router
    end

    def call(env)
      request = Rack::Request.new(env)
      endpoint = router.endpoint(request.path_info)

      case endpoint
      when :not_found
        not_found_response
      else
        [200, { "Content-Length" => "14" }, ["Test Response\n"]]
      end
    end

    private

    def html_wrap(title, content)  # :nodoc:
      <<-document.gsub(/^ {6}/, "")
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>#{title}</title></head>
      <body>
        #{content}
      </body>
      </html>
      document
    end

    def default_404_body  # :nodoc:
      html_wrap("Error", "<p>404: Not Found</p>")
    end

    def custom_404_body  # :nodoc:
      router.custom_404_body
    end

    def not_found_response  # :nodoc:
      body = custom_404_body || default_404_body

      response = Rack::Response.new(body)
      response.status = 404
      response["Content-Type"] = "text/html"

      response.finish
    end
  end
end
