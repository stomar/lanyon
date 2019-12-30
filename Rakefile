require "rake/testtask"
require "fileutils"


def gemspec_file
  "lanyon.gemspec"
end


task default: [:test]

Rake::TestTask.new do |t|
  t.pattern = "test/**/test_*.rb"
  t.verbose = true
  t.warning = true
end


desc "Build gem"
task :build do
  sh "gem build #{gemspec_file}"
end


desc "Remove generated files"
task :clean do
  FileUtils.rm_rf("demo/_site")
  FileUtils.rm_rf("demo/.jekyll-cache")
  FileUtils.rm(Dir.glob("*.gem"))
end


desc "Serve demo site"
task :demo do
  port = 4000
  puts "Starting server: http://localhost:#{port}/"
  Dir.chdir("demo") { sh "rackup -p #{port} -I ../lib" }
end
