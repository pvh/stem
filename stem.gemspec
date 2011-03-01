$spec = Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'stem'
  s.version = '0.5.0'
  s.date = '2011-02-25'

  s.description = "minimalist EC2 instance management"
  s.summary     = "an EC2 instance management library designed to get out of your way and give you instances"

  s.authors = ["Peter van Hardenberg", "Orion Henry", "Blake Gentry"]
  s.email = ["pvh@heroku.com", "orion@heroku.com", "b@heroku.com"]

  # = MANIFEST =
  s.files = %w[LICENSE README.md] + Dir["lib/**/*.rb"]

  s.executables = ["stem"]

  # = MANIFEST =
  s.add_dependency 'swirl',    '= 1.6.2'
  s.homepage = "http://github.com/pvh/stem"
  s.require_paths = %w[lib]
end
