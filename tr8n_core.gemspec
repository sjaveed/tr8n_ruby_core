$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "tr8n_core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "tr8n_core"
  s.version     = Tr8nCore::VERSION
  s.authors     = ["Michael Berkovich"]
  s.email       = ["theiceberk@gmail.com"]
  s.homepage    = "http://www.tr8nhub.com"
  s.summary     = "Tr8n Core Classes"
  s.description = "Tr8n core classes that can be used by any Ruby framework"

  s.files = Dir["{lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'activesupport'
  s.add_dependency 'faraday'
  s.add_dependency 'dalli'
end
