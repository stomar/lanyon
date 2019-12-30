# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "stringio"
require "rack/mock"

require "lanyon"


TEST_DIR = File.expand_path(__dir__)

SOURCE_DIR = File.join(TEST_DIR, "source")
CACHE_DIR = File.join(SOURCE_DIR, ".jekyll-cache")

TEMP_DIR = File.join(TEST_DIR, "tmp")


def setup_tempdir
  FileUtils.mkdir_p(TEMP_DIR)

  File.exist?(TEMP_DIR) ? TEMP_DIR : nil
end

def teardown_tempdir
  FileUtils.rm_rf(TEMP_DIR)  if File.exist?(TEMP_DIR)
end

def chdir_tempdir
  Dir.chdir(TEMP_DIR)
end

def teardown_cachedir
  FileUtils.rm_rf(CACHE_DIR)  if File.exist?(CACHE_DIR)
end

def sourcedir
  SOURCE_DIR
end

def silence_output
  original_stderr, original_stdout = $stderr, $stdout
  $stderr, $stdout = StringIO.new, StringIO.new

  yield
ensure
  $stderr, $stdout = original_stderr, original_stdout
end

def file_must_exist(filename)
  assert File.exist?(filename),
         "Expected file `#{filename}' to exist."
end

def file_wont_exist(filename)
  assert !File.exist?(filename),
         "Expected file `#{filename}' to not exist."
end
