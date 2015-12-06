# encoding: UTF-8

require_relative "helper"


def get_app(overrides = {})
  silence_output do
    Lanyon.application(overrides)
  end
end


describe "when handling requests" do

  before do
    tempdir = setup_tempdir
    chdir_tempdir

    @destdir = File.join(tempdir, "_site")

    app = get_app(:source => sourcedir, :destination => @destdir)
    @request = Rack::MockRequest.new(app)
  end

  after do
    teardown_tempdir
  end


  describe "when asked for '/'" do

    before do
      @response = @request.get("/")
    end

    it "returns status 200" do
      @response.status.must_equal 200
    end

    it "returns correct Content-Length header" do
      @response.original_headers["Content-Length"].must_equal "17"
    end

    it "returns correct Content-Type header" do
      @response.headers["Content-Type"].must_equal "text/html"
    end

    it "returns correct Last-Modified header" do
      mtime = File.mtime(@destdir + "/index.html")
      @response.headers["Last-Modified"].must_equal mtime.httpdate
    end

    it "returns correct body" do
      @response.body.must_match %r{<p>Home Page</p>}
    end
  end


  describe "when asked for a nonexistent path" do

    before do
      @response = @request.get("/not/a/page")
    end

    it "returns status 200" do
      @response.status.must_equal 404
    end

    it "returns correct Content-Length header" do
      @response.original_headers["Content-Length"].must_equal "142"
    end

    it "returns correct Content-Type header" do
      @response.headers["Content-Type"].must_equal "text/html"
    end

    it "returns correct body" do
      expected = %r{<!DOCTYPE html>.*<p>404: Not Found</p>}m
      @response.body.must_match expected
    end
  end


  describe "when asked for a nonexistent path and a custom 404 exists" do

    before do
      @custom_404 = File.join(sourcedir, "404.html")
      File.open(@custom_404, "w") {|f| f.print "Custom 404" }

      app = get_app(:source => sourcedir, :destination => @destdir)
      request = Rack::MockRequest.new(app)
      @response = request.get("/not/a/page")
    end

    after do
      FileUtils.rm(@custom_404)
    end

    it "returns correct Content-Length header" do
      @response.original_headers["Content-Length"].must_equal "10"
    end

    it "returns correct Content-Type header" do
      @response.headers["Content-Type"].must_equal "text/html"
    end

    it "returns correct body" do
      @response.body.must_equal "Custom 404"
    end
  end


  describe "when asked for an existing path" do

    before do
      @response = @request.get("/2015/11/05/hello-world.html")
    end

    it "returns status 200" do
      @response.status.must_equal 200
    end

    it "returns correct Content-Type header" do
      @response.headers["Content-Type"].must_equal "text/html"
    end

    it "returns correct Content-Length header" do
      @response.original_headers["Content-Length"].must_equal "19"
    end

    it "returns correct body" do
      @response.body.must_match %r{<p>A Blog Post</p>}
    end
  end


  describe "when asked for a resource without extension" do

    before do
      @response = @request.get("/no-extension")
    end

    it "returns status 200" do
      @response.status.must_equal 200
    end

    it "returns Content-Type 'application/octet-stream'" do
      type = @response.headers["Content-Type"]
      type.must_equal "application/octet-stream"
    end
  end


  describe "when asked for resources with various media types" do

    it "returns correct Content-Type for *.css" do
      type = @request.get("/css/test.css").headers["Content-Type"]
      type.must_equal "text/css"
    end

    it "returns correct Content-Type for *.min.js" do
      type = @request.get("/js/test.min.js").headers["Content-Type"]
      type.must_equal "application/javascript"
    end
  end


  describe "when asked for partially matching paths" do

    it "returns status 404 for path 1" do
      @request.get("/2015/10/05/hello").status.must_equal 404
    end

    it "returns status 404 for path 2" do
      @request.get("/10/05/hello-world.html").status.must_equal 404
    end
  end


  describe "when asked for paths with directory traversal" do

    it "returns status 404 for unsafe directory traversal" do
      filename = File.join(@destdir, "/../_site/index.html")
      assert File.exist?(filename)

      @response = @request.get("/../_site/index.html")
      @response.status.must_equal 404
    end
  end


  describe "when a directory is requested" do

    it "redirects to 'directory/' for 'directory' with index.html" do
      @request.get("/dir-with-index").status.must_equal 301
    end

    it "returns status 200 for 'directory/' with index.html" do
      @request.get("/dir-with-index/").status.must_equal 200
    end

    it "returns correct body for 'directory/' with index.html" do
      @request.get("/dir-with-index/").body.must_match %r{<p>Index of dir-with-index/</p>}
    end

    it "returns status 404 for 'directory' without index.html" do
      @request.get("/dir-without-index").status.must_equal 404
    end

    it "returns status 404 for 'directory/' without index.html" do
      @request.get("/dir-without-index/").status.must_equal 404
    end
  end


  describe "when redirecting to URL with trailing slash" do

    before do
      @response = @request.get("/dir-with-index")
    end

    it "returns status 301" do
      @response.status.must_equal 301
    end

    it "returns correct Location header" do
      @response.headers["Location"].must_equal "/dir-with-index/"
    end

    it "returns a Cache-Control header" do
      @response.headers["Cache-Control"].wont_be_nil
    end

    it "returns correct body" do
      expected = %r{<!DOCTYPE html>.*<a href="/dir-with-index/">}m
      @request.get("/dir-with-index").body.must_match expected
    end
  end


  describe "when page contains multibyte characters" do

    before do
      @response = @request.get("/buenos_dias.html")
    end

    it "returns correct body" do
      response_body = @response.body.force_encoding("UTF-8")
      response_body.must_match %r{<p>¡Buenos días!</p>}
    end

    it "returns the bytesize as Content-Length header" do
      @response.original_headers["Content-Length"].must_equal "23"
    end
  end


  describe "when resource contains CRLF newlines" do

    before do
      @response = @request.get("/crlf.dat")
    end

    it "returns correct body" do
      expected = "File\r\nwith\r\nCRLF\r\nnewlines\r\n"
      @response.body.must_equal expected
    end

    it "returns the bytesize as Content-Length header" do
      @response.original_headers["Content-Length"].must_equal "28"
    end
  end


  describe "when handling If-Modified-Since requests" do

    before do
      modify_time  = @request.get("/").headers["Last-Modified"]
      earlier_time = (Time.parse(modify_time) - 3600).httpdate
      @modify_time_header  = { "HTTP_IF_MODIFIED_SINCE" => modify_time }
      @earlier_time_header = { "HTTP_IF_MODIFIED_SINCE" => earlier_time }
    end

    it "returns correct status code for unchanged '/'" do
      @request.get("/", @modify_time_header).status.must_equal 304
    end

    it "does not return a Content-Length header for unchanged '/'" do
      response = @request.get("/", @modify_time_header)
      response.original_headers["Content-Length"].must_be_nil
    end

    it "returns correct status code for updated '/'" do
      @request.get("/", @earlier_time_header).status.must_equal 200
    end

    it "returns correct status code for 404" do
      @request.get("/not/a/page", @earlier_time_header).status.must_equal 404
    end
  end


  describe "when handling HEAD requests" do

    it "returns status 200 for '/'" do
      @request.head("/").status.must_equal 200
    end

    it "returns correct Content-Length header for '/'" do
      @request.head("/").original_headers["Content-Length"].must_equal "17"
    end

    it "does not return a body" do
      @request.head("/").body.must_equal ""
    end
  end


  describe "when handling OPTIONS requests" do

    it "returns status 200" do
      @request.options("/").status.must_equal 200
    end

    it "returns correct Allow header" do
      @request.options("/").original_headers["Allow"].must_equal "GET,HEAD,OPTIONS"
    end

    it "does not return a body" do
      @request.options("/").body.must_equal ""
    end

    it "returns 404 for nonexistent resource" do
      @request.options("/not/a/page").status.must_equal 404
      @request.options("/not/a/page").body.must_match %r{<p>404: Not Found</p>}
    end
  end


  describe "when handling POST, PUT, DELETE, and other requests" do

    it "returns status 405" do
      @request.post("/").status.must_equal 405
      @request.put("/").status.must_equal 405
      @request.delete("/").status.must_equal 405
      @request.request("OTHER", "/").status.must_equal 405
    end

    it "returns correct body" do
      expected = %r{<!DOCTYPE html>.*<p>405: Method Not Allowed</p>}m
      @request.post("/").body.must_match expected
    end
  end
end
