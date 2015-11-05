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

    destdir = File.join(tempdir, "_site")

    app = get_app(:source => sourcedir, :destination => destdir)
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
      @response.original_headers["Content-Length"].must_equal "14"
    end

    it "returns correct body" do
      @response.body.must_equal "Test Response\n"
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
      @response.original_headers["Content-Length"].must_equal "15"
    end

    it "returns correct body" do
      @response.body.must_equal "404: Not Found\n"
    end
  end
end
