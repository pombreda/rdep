Gem::Specification.new 'test', '0.0' do |s|
  s.name        = 'test_gem_61cdcl'
  s.version     = '0.0'
  s.summary     = "Test Ruby Gem"
  s.description = "Test gemspec"
  s.authors     = ["Ron Burgundy"]
  s.email       = 'ron@burgundy.com'
  s.files       = ["lib/ron.rb"]
  s.homepage    = 'https://sourcegraph.com'
  s.license     = 'MIT'
  s.require_path = 'lib'

  s.add_dependency 'test_dep_1', '>= 1.2.3'
  s.add_dependency 'test_dep' + '_2', '~> 2.3'
  s.add_dependency 'test_dep_3'
end
