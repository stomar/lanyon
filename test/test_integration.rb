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
  end


  describe "when asked for partially matching paths" do

    it "returns status 404 for path 1" do
      @request.get("/2015/10/05/hello").status.must_equal 404
    end

    it "returns status 404 for path 2" do
      @request.get("/10/05/hello-world.html").status.must_equal 404
    end
  end


  describe "when a directory is requested" do

    it "redirects to 'directory/' for 'directory' with index.html" do
      skip
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


  describe "when page contains multibyte characters" do

    before do
      @response = @request.get("/buenos_dias.html")
    end

    it "returns correct body" do
      @response.body.must_match %r{<p>¡Buenos días!</p>}
    end

    it "returns the bytesize as Content-Length header" do
      @response.original_headers["Content-Length"].must_equal "23"
    end
  end
end
