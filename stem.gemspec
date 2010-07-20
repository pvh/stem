Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'stem'
  s.version = '0.1'
  s.date = '2010-06-28'

  s.description = "minimalist EC2 instance management"
  s.summary     = s.description

  s.authors = ["Peter van Hardenberg"]

  # = MANIFEST =
  s.files = %w[LICENSE README.md] + Dir["lib/**/*.rb"]

  s.executables = ["stem"]

  # = MANIFEST =
  s.add_dependency 'swirl',    '= 1.5.2'
  s.homepage = "http://github.com/pvh/stem"
  s.require_paths = %w[lib]
end
