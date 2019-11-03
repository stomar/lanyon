require_relative "lib/lanyon/version"

version  = Lanyon::VERSION
date     = Lanyon::DATE

Gem::Specification.new do |s|
  s.name              = "lanyon"
  s.version           = version
  s.date              = date

  s.summary = "Lanyon serves your Jekyll site as a Rack application."
  s.description =
    "Lanyon is a good friend of Jekyll, the static site generator, " +
    "and transforms your website into a Rack application."

  s.authors = ["Marcus Stollsteimer"]
  s.email = "sto.mar@web.de"
  s.homepage = "https://github.com/stomar/lanyon/"

  s.license = "MIT"

  s.required_ruby_version = ">= 2.0.0"

  s.add_dependency "jekyll", ">= 2.0"
  s.add_dependency "rack", ">= 1.6", "< 3.0"

  s.add_development_dependency "rake", "~> 11.2"
  s.add_development_dependency "minitest", "~> 5.8"

  s.require_paths = ["lib"]

  s.files = %w[
      README.md
      LICENSE
      History.md
      lanyon.gemspec
      Gemfile
      Rakefile
      .yardopts
    ] +
    Dir.glob("lib/**/*") +
    Dir.glob("test/**/*") +
    Dir.glob("demo/**/*").reject {|f| f =~ %r(\Ademo/_site/) }

  s.extra_rdoc_files = %w[README.md LICENSE History.md]
  s.rdoc_options = ["--charset=UTF-8", "--main=README.md"]
end
