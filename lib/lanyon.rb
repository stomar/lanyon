# = lanyon.rb
#
# See Lanyon module for documentation.

require "jekyll"

require "lanyon/application"
require "lanyon/version"


# Lanyon serves your Jekyll site as a Rack application.
#
# See Lanyon.application for available initialization options.
#
# Further information on the Lanyon library is available in the README file
# or on the project home page: <https://github.com/stomar/lanyon/>.
#
module Lanyon

  # Builds the Jekyll site and returns a Rack application.
  #
  # Options:
  #
  # +:config+::      use given config file (default: "_config.yml")
  #
  # +:skip_build+::  whether to skip site generation at startup
  #                  (default: +false+)
  #
  # Other options are passed on to Jekyll::Site.
  #
  # Returns a Rack application.
  def self.application(options = {})
    skip_build = options.fetch(:skip_build, default_options[:skip_build])

    config = jekyll_config(options)

    if skip_build
      puts skip_build_warning
    else
      build(config)
    end

    Application.new
  end

  # @private
  def self.default_options  # :nodoc:
    { :skip_build => false }
  end

  # @private
  def self.jekyll_config(overrides = {})  # :nodoc:
    overrides = overrides.dup
    default_options.each_key {|key| overrides.delete(key) }

    ::Jekyll.configuration(overrides)
  end

  # @private
  def self.skip_build_warning  # :nodoc:
    "Build warning: Skipping the initial build."
  end

  # @private
  def self.build(config)  # :nodoc:
    site = ::Jekyll::Site.new(config)
    puts "Generating site: #{site.source} -> #{site.dest}"
    site.process
  end
end
