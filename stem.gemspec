$spec = Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'stem'
  s.version = '0.5.6'
  s.date = '2011-03-07'

  s.description = "minimalist EC2 instance management"
  s.summary     = "an EC2 instance management library designed to get out of your way and give you instances"

  s.authors = ["Peter van Hardenberg", "Orion Henry", "Blake Gentry"]
  s.email = ["pvh@heroku.com", "orion@heroku.com", "b@heroku.com"]

  # = MANIFEST =
  s.files = %w[LICENSE README.md] + Dir["lib/**/*.rb"]

  s.executables = ["stem"]

  # = MANIFEST =
  s.add_dependency 'swirl',    '~> 1.7.5'
  s.add_development_dependency 'rspec', '~> 2.5.0'
  s.add_development_dependency 'rspec-core', '~> 2.5.0'
  s.add_development_dependency 'rspec-expectations', '~> 2.5.0'
  s.add_development_dependency 'rspec-mocks', '~> 2.5.0'
  s.add_development_dependency 'vcr', '~> 1.6.0'
  s.add_development_dependency 'webmock', '~> 1.6.2'
  s.homepage = "http://github.com/pvh/stem"
  s.require_paths = %w[lib]
end
