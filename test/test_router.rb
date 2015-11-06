require_relative "helper"


describe Lanyon::Router do

  before do
    tempdir = setup_tempdir
    chdir_tempdir

    @sitedir = File.join(tempdir, "_site")
    FileUtils.mkdir_p(@sitedir)

    files = %w[
      index.html
      page.html
      README
      dir-with-index/index.html
      dir-without-index/page.html
      dir1/dir2/dir3/index.html
    ]

    files.each do |path|
      dirname = File.dirname(path)
      FileUtils.mkdir_p(File.join(@sitedir, dirname))
      FileUtils.touch(File.join(@sitedir, path))
    end

    @router = Lanyon::Router.new(@sitedir)
  end

  after do
    teardown_tempdir
  end


  describe "when asked for filenames with #endpoint" do

    it "returns path for '/'" do
      filename = File.join(@sitedir, "index.html")
      @router.endpoint("/").must_equal filename
    end

    it "returns existing path" do
      filename = File.join(@sitedir, "page.html")
      @router.endpoint("/page.html").must_equal filename
    end

    it "returns existing path for resource without extension" do
      filename = File.join(@sitedir, "README")
      @router.endpoint("/README").must_equal filename
    end

    it "returns :not_found for non-existent path" do
      @router.endpoint("/not-a-page.html").must_equal :not_found
    end

    it "returns :not_found for partially matching paths" do
      @router.endpoint("/dir1/dir2/").must_equal :not_found
      @router.endpoint("/dir2/dir3").must_equal :not_found
      @router.endpoint("ir1/di").must_equal :not_found
    end

    it "returns path for '/path/to/dir/' with index" do
      filename = File.join(@sitedir, "dir-with-index/index.html")
      @router.endpoint("/dir-with-index/").must_equal filename
    end

    it "returns :not_found for '/path/to/dir' with index" do
      @router.endpoint("/dir-with-index").must_equal :not_found
    end

    it "returns :not_found for '/path/to/dir/' without index" do
      @router.endpoint("/dir-without-index/").must_equal :not_found
    end

    it "returns :not_found for '/path/to/dir' without index" do
      @router.endpoint("/dir-without-index").must_equal :not_found
    end
  end


  describe "when asked for #custom_404_body" do

    describe "when 404.html does not exist" do

      it "returns nil" do
        @router.custom_404_body.must_be_nil
      end
    end

    describe "when 404.html does exist" do

      before do
        @custom_404 = File.join(@sitedir, "404.html")
        File.open(@custom_404, "w") {|f| f.print "Custom 404" }
      end

      after do
        FileUtils.rm(@custom_404)
      end

      it "returns correct body" do
        @router.custom_404_body.must_equal "Custom 404"
      end
    end
  end


  describe "when initialized" do

    it "strips trailing slash from root" do
      router = Lanyon::Router.new(@sitedir + "/")
      router.root.must_equal @sitedir
    end

    it "does not append a trailing slash to root" do
      assert !@sitedir.end_with?("/")

      router = Lanyon::Router.new(@sitedir)
      router.root.must_equal @sitedir
    end
  end
end
