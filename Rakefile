require "rake/testtask"


def gemspec_file
  "lanyon.gemspec"
end


task :default => [:test]

Rake::TestTask.new do |t|
  t.pattern = "test/**/test_*.rb"
  t.verbose = true
  t.warning = true
end


desc "Build gem"
task :build do
  sh "gem build #{gemspec_file}"
end
