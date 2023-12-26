# frozen_string_literal: true

require_relative "helper"


describe "when creating a Lanyon application" do

  before do
    tempdir = setup_tempdir
    chdir_tempdir

    destdir = File.join(tempdir, "_site")

    @dir_options = { source: sourcedir, destination: destdir }
    @page = File.join(destdir, "index.html")
    @no_page = File.join(destdir, "not_a_page.html")

    FileUtils.mkdir_p(destdir)
    FileUtils.touch(@no_page)
    assert File.exist?(@no_page)
    assert !File.exist?(@page)
  end

  after do
    teardown_tempdir
    teardown_cachedir
  end

  it "builds the site by default, removing old content" do
    silence_output do
      Lanyon.application(@dir_options)
    end

    file_must_exist(@page)
    file_wont_exist(@no_page)
  end

  it "does not build the site when :skip_build option is set" do
    options = { skip_build: true }.merge(@dir_options)
    silence_output do
      Lanyon.application(options)
    end

    file_must_exist(@no_page)
    file_wont_exist(@page)
  end

  it "does always build the site with ::build" do
    options = { skip_build: true }.merge(@dir_options)
    silence_output do
      Lanyon.build(options)
    end

    file_must_exist(@page)
    file_wont_exist(@no_page)
  end
end
