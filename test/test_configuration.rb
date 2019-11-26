# frozen_string_literal: true

require_relative "helper"


def get_jekyll_config(overrides = {})
  silence_output do
    Lanyon.jekyll_config(overrides)
  end
end


describe "when configuring site" do

  before do
    setup_tempdir
    chdir_tempdir
  end

  after do
    teardown_tempdir
  end

  describe "when no options are given and no config file exists" do

    it "loads the correct default destination" do
      config = get_jekyll_config
      _(config["destination"]).must_equal File.join(Dir.pwd, "_site")
    end
  end

  describe "when using default config file" do

    before do
      File.open("_config.yml", "w") do |f|
        f.puts "config_file_opt: ok"
      end
    end

    after do
      FileUtils.rm("_config.yml")
    end

    it "loads the configuration from file" do
      config = get_jekyll_config
      _(config).must_include "config_file_opt"
      _(config["config_file_opt"]).must_equal "ok"
    end
  end

  describe "when using custom config file" do

    before do
      File.open("_my_config.yml", "w") do |f|
        f.puts "config_file_opt: ok"
      end
    end

    after do
      FileUtils.rm("_my_config.yml")
    end

    it "loads the configuration from file" do
      config = get_jekyll_config(:config => "_my_config.yml")
      _(config).must_include "config_file_opt"
      _(config["config_file_opt"]).must_equal "ok"
    end
  end

  describe "when initialization options are given" do

    it "has the initialization options" do
      config = get_jekyll_config(:init_opt => "ok")
      _(config).must_include "init_opt"
      _(config["init_opt"]).must_equal "ok"
    end

    it "has the correct destination" do
      config = get_jekyll_config(:destination => "/project/_site")
      _(config["destination"]).must_equal "/project/_site"
    end

    it "does not pass :skip_build on to Jekyll" do
      config = get_jekyll_config(:skip_build => "ok")
      _(config).wont_include "skip_build"
    end
  end

  describe "when initialization options are given and a config file exists" do

    before do
      File.open("_config.yml", "w") do |f|
        f.puts "config_file_opt: ok"
        f.puts "common_opt:      from config"
        f.puts "destination:     /project/_site_from_config"
      end
    end

    after do
      FileUtils.rm("_config.yml")
    end

    it "has all options and initialization options override file options" do
      config = get_jekyll_config(:init_opt   => "ok",
                                 :common_opt => "from init")
      _(config).must_include "init_opt"
      _(config).must_include "config_file_opt"
      _(config).must_include "common_opt"
      _(config["common_opt"]).must_equal "from init"
    end

    it "has the correct destination" do
      config = get_jekyll_config(:destination => "/project/_site_from_init")
      _(config["destination"]).must_equal "/project/_site_from_init"
    end
  end
end
