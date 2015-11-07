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
      fullpath = File.join(@root, path)

      if fullpath.end_with?("/")
        normalized = fullpath + "index.html"
      else
        normalized = fullpath
      end

      endpoint = if FileTest.file?(normalized)
                   normalized
                 elsif needs_redirect_to_dir?(normalized)
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
  end
end
