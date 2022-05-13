# frozen_string_literal: true

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
      foo
      foo.html
      bar.html
      bar/index.html
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
      _(@router.endpoint("/")).must_equal filename
    end

    it "returns existing path" do
      filename = File.join(@sitedir, "page.html")
      _(@router.endpoint("/page.html")).must_equal filename
    end

    it "returns existing path for resource without extension" do
      filename = File.join(@sitedir, "README")
      _(@router.endpoint("/README")).must_equal filename
    end

    it "returns :not_found for non-existent path" do
      _(@router.endpoint("/not-a-page.html")).must_equal :not_found
    end

    it "returns :not_found for partially matching paths" do
      _(@router.endpoint("/dir1/dir2/")).must_equal :not_found
      _(@router.endpoint("/dir2/dir3")).must_equal :not_found
      _(@router.endpoint("ir1/di")).must_equal :not_found
    end

    it "returns path for '/path/to/dir/' with index" do
      filename = File.join(@sitedir, "dir-with-index/index.html")
      _(@router.endpoint("/dir-with-index/")).must_equal filename
    end

    it "returns :must_redirect for '/path/to/dir' with index" do
      _(@router.endpoint("/dir-with-index")).must_equal :must_redirect
    end

    it "returns :not_found for '/path/to/dir/' without index" do
      _(@router.endpoint("/dir-without-index/")).must_equal :not_found
    end

    it "returns :not_found for '/path/to/dir' without index" do
      _(@router.endpoint("/dir-without-index")).must_equal :not_found
    end
  end


  describe "when automatically adding .html extension" do

    it "returns existing path" do
      filename = File.join(@sitedir, "page.html")
      _(@router.endpoint("/page")).must_equal filename
    end

    describe "when both `foo' and `foo.html' exist" do

      it "returns `foo' and not `foo.html' when asked for `foo'" do
        filename = File.join(@sitedir, "foo")
        _(@router.endpoint("/foo")).must_equal filename
      end

      it "can also serve `foo.html'" do
        filename = File.join(@sitedir, "foo.html")
        _(@router.endpoint("/foo.html")).must_equal filename
      end
    end

    describe "when both `bar.html' and `bar/index.html' exist" do

      it "returns :must_redirect and not `bar.html' when asked for `bar'" do
        _(@router.endpoint("/bar")).must_equal :must_redirect
      end

      it "can also serve `bar.html'" do
        filename = File.join(@sitedir, "bar.html")
        _(@router.endpoint("/bar.html")).must_equal filename
      end
    end
  end


  describe "when asked for paths with directory traversal" do

    it "discards leading '..' for existing path" do
      filename = File.join(@sitedir, "page.html")
      _(@router.endpoint("/../../page.html")).must_equal filename
    end

    it "allows safe directory traversal" do
      filename = File.join(@sitedir, "index.html")
      _(@router.endpoint("/dir1/../")).must_equal filename
    end

    it "returns :not_found for unsafe directory traversal 1" do
      filename = File.join(@sitedir, "/../_site/page.html")
      assert File.exist?(filename)

      _(@router.endpoint("/../_site/page.html")).must_equal :not_found
    end

    it "returns :not_found for unsafe directory traversal 2" do
      _(@router.endpoint("/%2E%2E/_site/")).must_equal :not_found
    end

    it "returns :not_found for unsafe directory traversal 3" do
      _(@router.endpoint("/dir1/../dir1/../../_site/")).must_equal :not_found
    end
  end


  describe "when asked for #custom_404_body" do

    describe "when 404.html does not exist" do

      it "returns nil" do
        _(@router.custom_404_body).must_be_nil
      end
    end

    describe "when 404.html does exist" do

      before do
        @custom_404_file = File.join(@sitedir, "404.html")
        File.open(@custom_404_file, "w") {|f| f.print "Custom 404" }
      end

      after do
        FileUtils.rm(@custom_404_file)
      end

      it "returns correct body" do
        _(@router.custom_404_body).must_equal "Custom 404"
      end
    end
  end


  describe "when initialized" do

    it "strips trailing slash from root" do
      router = Lanyon::Router.new("#{@sitedir}/")
      _(router.root).must_equal @sitedir
    end

    it "does not append a trailing slash to root" do
      assert !@sitedir.end_with?("/")

      router = Lanyon::Router.new(@sitedir)
      _(router.root).must_equal @sitedir
    end
  end
end
