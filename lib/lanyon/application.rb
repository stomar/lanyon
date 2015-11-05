require "rack/request"


module Lanyon

  # Rack application that serves the Jekyll site.
  #
  # Not to be instantiated directly, use Lanyon.application instead.
  class Application

    def call(env)
      request = Rack::Request.new(env)

      if request.path_info == "/"
        [200, { "Content-Length" => "14" }, ["Test Response\n"]]
      else
        [404, { "Content-Length" => "15" }, ["404: Not Found\n"]]
      end
    end
  end
end
