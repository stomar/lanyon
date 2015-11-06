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
end
