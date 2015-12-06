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
    # - +:not_found+ if no corresponding file exists,
    # - +:must_redirect+ if the request must be redirected to <tt>path/</tt>.
    #
    def endpoint(path)
      normalized = normalize_path_info(path)

      fullpath = File.join(@root, normalized)
      endpoint = if FileTest.file?(fullpath)
                   fullpath
                 elsif needs_redirect_to_dir?(fullpath)
                   :must_redirect
                 else
                   :not_found
                 end

      endpoint
    end

    # Returns the body of the custom 404 page or +nil+ if none exists.
    def custom_404_body
      filename = File.join(root, "404.html")

      File.exist?(filename) ? File.read(filename) : nil
    end

    private

    def needs_redirect_to_dir?(fullpath)  # :nodoc:
      !fullpath.end_with?("/") && FileTest.file?(fullpath + "/index.html")
    end

    def normalize_path_info(path)
      if path.end_with?("/")
        normalized = path + "index.html"
      else
        normalized = path
      end

      Rack::Utils.clean_path_info(normalized)
    end
  end
end
