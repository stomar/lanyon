# frozen_string_literal: true

require "rack/utils"


module Lanyon

  # Router class for Lanyon applications.
  class Router

    attr_reader :root

    # Creates a Router for the given root directory.
    def initialize(root)
      @root = File.expand_path(root)
    end

    # Returns the full file system path of the file corresponding to
    # the given URL +path+, or
    #
    # - +:must_redirect+ if the request must be redirected to +path/+,
    # - +:not_found+ if no corresponding file exists.
    #
    # The return value is found as follows:
    #
    # 1. a +path/+ with a trailing slash is changed to +path/index.html+,
    # 2. then, the method checks for an exactly corresponding file,
    # 3. when +path+ does not exist but +path/index.html+ does,
    #    a redirect will be indicated,
    # 4. finally, when no exactly corresponding file or redirect
    #    can be found, +path.html+ is tried.
    def endpoint(path)
      normalized = normalize_path_info(path)

      fullpath = File.join(@root, normalized)
      endpoint = if FileTest.file?(fullpath)
                   fullpath
                 elsif needs_redirect_to_dir?(fullpath)
                   :must_redirect
                 elsif FileTest.file?(fullpath_html = "#{fullpath}.html")
                   fullpath_html
                 else
                   :not_found
                 end

      endpoint
    end

    # Returns the body of the custom 404 page or +nil+ if none exists.
    def custom_404_body
      filename = File.join(root, "404.html")

      File.exist?(filename) ? File.binread(filename) : nil
    end

    private

    def needs_redirect_to_dir?(fullpath)  # :nodoc:
      !fullpath.end_with?("/") && FileTest.file?(fullpath + "/index.html")
    end

    def unescape_path(path)  # :nodoc:
      Rack::Utils.unescape_path(path)
    end

    def normalize_path_info(path_info)  # :nodoc:
      path = unescape_path(path_info)

      path << "index.html"  if path.end_with?("/")

      Rack::Utils.clean_path_info(path)
    end
  end
end
