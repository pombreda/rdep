Gem::Specification.new do |s|
  s.name         = 'rdep'
  s.version      = '0.0.4d'
  s.date         = '2014-04-18'
  s.summary      = "Command line utility for displaying gem dependency metadata in JSON"
  s.description  = "See summary"
  s.authors      = ["Beyang Liu"]
  s.email        = 'beyang@sourcegraph.com'
  s.files        = ["lib/rdep.rb", "bin/rdep"]
  s.homepage     = 'https://sourcegraph.com'
  s.license      = 'Apache 2'
  s.require_path = 'lib'
  s.bindir       = 'bin'
  s.executables  = ['rdep']

  s.add_dependency 'bundler', '~> 1.6.2', '>= 1.6'
end
