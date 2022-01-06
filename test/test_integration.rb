# frozen_string_literal: true

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

    app = get_app(source: sourcedir, destination: @destdir)
    @request = Rack::MockRequest.new(app)
  end

  after do
    teardown_tempdir
    teardown_cachedir
  end


  describe "when asked for '/'" do

    before do
      @response = @request.get("/")
    end

    it "returns status 200" do
      _(@response.status).must_equal 200
    end

    it "returns correct Content-Length header" do
      _(@response.original_headers["Content-Length"]).must_equal "17"
    end

    it "returns correct Content-Type header" do
      _(@response.headers["Content-Type"]).must_equal "text/html"
    end

    it "returns an ETag header" do
      _(@response.headers["ETag"]).wont_be_nil
    end

    it "returns correct body" do
      _(@response.body).must_match %r{<p>Home Page</p>}
    end
  end


  describe "when asked for a nonexistent path" do

    before do
      @response = @request.get("/not/a/page")
    end

    it "returns status 404" do
      _(@response.status).must_equal 404
    end

    it "returns correct Content-Length header" do
      _(@response.original_headers["Content-Length"]).must_equal "142"
    end

    it "returns correct Content-Type header" do
      _(@response.headers["Content-Type"]).must_equal "text/html"
    end

    it "returns correct body" do
      expected = %r{<!DOCTYPE html>.*<p>404: Not Found</p>}m
      _(@response.body).must_match expected
    end
  end


  describe "when asked for a nonexistent path and a custom 404 exists" do

    before do
      @custom_404 = File.join(sourcedir, "404.html")
      File.open(@custom_404, "w") {|f| f.print "Custom 404" }

      app = get_app(source: sourcedir, destination: @destdir)
      request = Rack::MockRequest.new(app)
      @response = request.get("/not/a/page")
    end

    after do
      FileUtils.rm(@custom_404)
    end

    it "returns correct Content-Length header" do
      _(@response.original_headers["Content-Length"]).must_equal "10"
    end

    it "returns correct Content-Type header" do
      _(@response.headers["Content-Type"]).must_equal "text/html"
    end

    it "returns correct body" do
      _(@response.body).must_equal "Custom 404"
    end
  end


  describe "when asked for an existing path" do

    before do
      @response = @request.get("/2015/11/05/hello-world.html")
    end

    it "returns status 200" do
      _(@response.status).must_equal 200
    end

    it "returns correct Content-Type header" do
      _(@response.headers["Content-Type"]).must_equal "text/html"
    end

    it "returns correct Content-Length header" do
      _(@response.original_headers["Content-Length"]).must_equal "19"
    end

    it "returns correct body" do
      _(@response.body).must_match %r{<p>A Blog Post</p>}
    end
  end


  describe "when asked for a resource without extension" do

    before do
      @response = @request.get("/no-extension")
    end

    it "returns status 200" do
      _(@response.status).must_equal 200
    end

    it "returns Content-Type 'application/octet-stream'" do
      type = @response.headers["Content-Type"]
      _(type).must_equal "application/octet-stream"
    end
  end


  describe "when asked for resources with various media types" do

    it "returns correct Content-Type for *.css" do
      type = @request.get("/css/test.css").headers["Content-Type"]
      _(type).must_equal "text/css"
    end

    it "returns correct Content-Type for *.min.js" do
      type = @request.get("/js/test.min.js").headers["Content-Type"]
      _(type).must_equal "application/javascript"
    end
  end


  describe "when asked for partially matching paths" do

    it "returns status 404 for path 1" do
      _(@request.get("/2015/10/05/hello").status).must_equal 404
    end

    it "returns status 404 for path 2" do
      _(@request.get("/10/05/hello-world.html").status).must_equal 404
    end
  end


  describe "when asked for paths with directory traversal" do

    it "returns status 404 for unsafe directory traversal" do
      filename = File.join(@destdir, "/../_site/index.html")
      assert File.exist?(filename)

      response = @request.get("/../_site/index.html")
      _(response.status).must_equal 404
    end
  end


  describe "when a directory is requested" do

    it "redirects to 'directory/' for 'directory' with index.html" do
      _(@request.get("/dir-with-index").status).must_equal 301
    end

    it "returns status 200 for 'directory/' with index.html" do
      _(@request.get("/dir-with-index/").status).must_equal 200
    end

    it "returns correct body for 'directory/' with index.html" do
      response_body = @request.get("/dir-with-index/").body
      _(response_body).must_match %r{<p>Index of dir-with-index/</p>}
    end

    it "returns status 404 for 'directory' without index.html" do
      _(@request.get("/dir-without-index").status).must_equal 404
    end

    it "returns status 404 for 'directory/' without index.html" do
      _(@request.get("/dir-without-index/").status).must_equal 404
    end
  end


  describe "when redirecting to URL with trailing slash" do

    before do
      @response = @request.get("/dir-with-index")
    end

    it "returns status 301" do
      _(@response.status).must_equal 301
    end

    it "returns correct Location header" do
      _(@response.headers["Location"]).must_equal "/dir-with-index/"
    end

    it "returns a Cache-Control header" do
      _(@response.headers["Cache-Control"]).wont_be_nil
    end

    it "returns correct body" do
      expected = %r{<!DOCTYPE html>.*<a href="/dir-with-index/">}m
      _(@request.get("/dir-with-index").body).must_match expected
    end
  end


  describe "when page contains multibyte characters" do

    before do
      @response = @request.get("/buenos_dias.html")
    end

    it "returns correct body" do
      response_body = @response.body.force_encoding("UTF-8")
      _(response_body).must_match %r{<p>¡Buenos días!</p>}
    end

    it "returns the bytesize as Content-Length header" do
      _(@response.original_headers["Content-Length"]).must_equal "23"
    end
  end


  describe "when resource contains CRLF newlines" do

    before do
      @response = @request.get("/crlf.dat")
    end

    it "returns correct body" do
      expected = "File\r\nwith\r\nCRLF\r\nnewlines\r\n"
      _(@response.body).must_equal expected
    end

    it "returns the bytesize as Content-Length header" do
      _(@response.original_headers["Content-Length"]).must_equal "28"
    end
  end


  describe "when URL contains special characters" do

    it "returns status 200 for URL with escapes" do
      response = @request.get("%2F2015%2F11%2F05%2Fhello-world.html")
      _(response.status).must_equal 200
    end

    it "returns status 200 for resource name with blank" do
      response = @request.get("with%20blank.html")
      _(response.status).must_equal 200
    end

    it "returns status 200 for resource name with plus" do
      response = @request.get("with+plus.html")
      _(response.status).must_equal 200
    end
  end


  describe "when handling caching with ETag" do

    before do
      etag  = @request.get("/").headers["ETag"]
      other = @request.get("/no-extension").headers["ETag"]
      assert  etag.start_with?("W/")
      assert other.start_with?("W/")

      @correct_etag = { "HTTP_IF_NONE_MATCH" => etag }
      @other_etag   = { "HTTP_IF_NONE_MATCH" => other }
    end

    it "returns correct status code for unchanged '/'" do
      _(@request.get("/", @correct_etag).status).must_equal 304
    end

    it "does not return a Content-Length header for unchanged '/'" do
      response = @request.get("/", @correct_etag)
      _(response.original_headers["Content-Length"]).must_be_nil
    end

    it "returns correct status code for changed '/'" do
      _(@request.get("/", @other_etag).status).must_equal 200
    end

    it "returns correct status code for 404" do
      _(@request.get("/not/a/page", @other_etag).status).must_equal 404
    end
  end


  describe "when handling HEAD requests" do

    it "returns status 200 for '/'" do
      _(@request.head("/").status).must_equal 200
    end

    it "returns correct Content-Length header for '/'" do
      _(@request.head("/").original_headers["Content-Length"]).must_equal "17"
    end

    it "does not return a body" do
      _(@request.head("/").body).must_equal ""
    end
  end


  describe "when handling OPTIONS requests" do

    it "returns status 200" do
      _(@request.options("/").status).must_equal 200
    end

    it "returns correct Allow header" do
      response_allow_header = @request.options("/").original_headers["Allow"]
      _(response_allow_header).must_equal "GET,HEAD,OPTIONS"
    end

    it "does not return a body" do
      _(@request.options("/").body).must_equal ""
    end

    it "returns 404 for nonexistent resource" do
      _(@request.options("/not/a/page").status).must_equal 404
      _(@request.options("/not/a/page").body).must_match %r{<p>404: Not Found</p>}
    end
  end


  describe "when handling POST, PUT, DELETE, and other not allowed requests" do

    it "returns status 405" do
      _(@request.post("/").status).must_equal 405
      _(@request.put("/").status).must_equal 405
      _(@request.delete("/").status).must_equal 405
      _(@request.request("OTHER", "/").status).must_equal 405
    end

    it "returns correct body" do
      expected = %r{<!DOCTYPE html>.*<p>405: Method Not Allowed</p>}m
      _(@request.post("/").body).must_match expected
    end

    it "returns correct Content-Length header" do
      _(@request.post("/").original_headers["Content-Length"]).must_equal "151"
    end
  end
end
