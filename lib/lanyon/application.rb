# frozen_string_literal: true

require "rack/mime"
require "rack/request"
require "rack/response"
require "time"


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
        case request.request_method
        when "HEAD", "GET"
          response(endpoint)
        when "OPTIONS"
          [200, { "Allow" => "GET,HEAD,OPTIONS", "Content-Length" => "0" }, []]
        else
          not_allowed_response
        end
      end
    end

    private

    def response(filename)  # :nodoc:
      response = Rack::Response.new(File.binread(filename))
      response["Content-Type"]  = media_type(filename)

      response.finish
    end

    def html_response(body, status, headers = {})  # :nodoc:
      response = Rack::Response.new(body, status, headers)
      response["Content-Type"] = "text/html"

      response.finish
    end

    def media_type(filename)  # :nodoc:
      extension = ::File.extname(filename)

      Rack::Mime.mime_type(extension)
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

      html_response(body, 404)
    end

    def not_allowed_response  # :nodoc:
      body = html_wrap("Error", "<p>405: Method Not Allowed</p>")

      html_response(body, 405)
    end

    def redirect_body(to_path)  # :nodoc:
      message = %Q{<p>Redirecting to <a href="#{to_path}">#{to_path}</a>.</p>}

      html_wrap("Redirection", message)
    end

    def redirect_to_dir_response(from_path)  # :nodoc:
      location = from_path.dup
      location << "/"  unless location.end_with?("/")

      cache_time = 3600

      body = redirect_body(location)
      headers = {
        "Location"      => location,
        "Cache-Control" => "max-age=#{cache_time}, must-revalidate",
        "Expires"       => (Time.now + cache_time).httpdate
      }

      html_response(body, 301, headers)
    end
  end
end
