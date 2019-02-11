require File.expand_path("../lib/tag_columns/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "tag_columns"
  gem.license     = "MIT"
  gem.version     = TagColumns::VERSION
  gem.authors     = ["Nathan Hopkins"]
  gem.email       = ["natehop@gmail.com"]
  gem.homepage    = "https://github.com/hopsoft/tag_columns"
  gem.summary     = "Fast & simple Rails ActiveRecord model tagging using PostgreSQL's Array datatype"

  gem.files       = Dir["lib/**/*.rb", "bin/*", "[A-Z]*"]
  gem.test_files  = Dir["test/**/*.rb"]

  gem.add_dependency "activesupport"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "pry-test"
  gem.add_development_dependency "coveralls"
end
