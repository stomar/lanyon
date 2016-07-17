require "uri"


module Lanyon
  module Backports  # :nodoc:
    class Router

      # Backport for Rack 1.x
      module UnescapePath

        def unescape_path(path)
          URI::Parser.new.unescape(path)
        end
      end
    end
  end


  Router.prepend Backports::Router::UnescapePath  if Rack.release.start_with?("1.")
end
