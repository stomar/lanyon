module Lanyon

  # Router class for Lanyon applications.
  class Router

    attr_reader :root

    # Creates a Router for the given root directory.
    def initialize(root)
      @root = File.expand_path(root)
    end

    # Returns the full file system path of the file corresponding to
    # the given URL path, or +:not_found+ if no corresponding file exists.
    def endpoint(path)
      fullpath = File.join(@root, path)

      if fullpath.end_with?("/")
        normalized = fullpath + "index.html"
      else
        normalized = fullpath
      end

      FileTest.file?(normalized) ? normalized : :not_found
    end

    # Returns the body of the custom 404 page or +nil+ if none exists.
    def custom_404_body
      filename = File.join(root, "404.html")

      File.exist?(filename) ? File.read(filename) : nil
    end
  end
end
