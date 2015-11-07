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
      when :must_redirect
        redirect_to_dir_response(request.path_info)
      else
        response(endpoint)
      end
    end

    private

    def response(filename)  # :nodoc:
      response = Rack::Response.new(File.read(filename))

      response.finish
    end

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

    def redirect_message(to_path)  # :nodoc:
      %Q{<a href="#{to_path}">#{to_path}</a>\n}
    end

    def redirect_to_dir_response(from_path)  # :nodoc:
      location = from_path.dup
      location << "/"  unless location.end_with?("/")

      cache_time = 3600

      body = redirect_message(location)

      response = Rack::Response.new(body)
      response.status = 301
      response["Location"]      = location
      response["Cache-Control"] = "max-age=#{cache_time}, must-revalidate"
      response["Expires"]       = (Time.now + cache_time).httpdate

      response.finish
    end
  end
end
