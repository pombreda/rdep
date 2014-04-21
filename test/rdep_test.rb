require '../lib/rdep'
require 'test/unit'
require 'bundler'

class TestRDep < Test::Unit::TestCase
  def test_load_gemspec
    g = RDep::load_gemspec('test_gem/test_gem.gemspec')
    assert_equal('test_gem_61cdcl', g.name)
    assert_equal(Gem::Version.new('0.0'), g.version)
    assert_equal("Test Ruby Gem", g.summary)
    assert_equal("Test gemspec", g.description)
    assert_equal(["Ron Burgundy"], g.authors)
    assert_equal('ron@burgundy.com', g.email)
    assert_equal(["lib/ron.rb"], g.files)
    assert_equal('https://sourcegraph.com', g.homepage)
    assert_equal('MIT', g.license)
    assert_equal('lib', g.require_path)
    assert_equal([
                  Gem::Dependency.new('test_dep_1', '>= 1.2.3'),
                  Gem::Dependency.new('test_dep_2', '~> 2.3'),
                  Gem::Dependency.new('test_dep_3', '>= 0'),
                 ], g.dependencies)
  end

  def test_load_gemfile
    g = RDep::load_gemfile('test_gem/Gemfile')
    assert_equal([
                  Bundler::Dependency.new('test_gem_61cdcl', '>= 0'),
                  Bundler::Dependency.new('dev_gem_1', '>= 0'),
                  Bundler::Dependency.new('dev_gem_2', '~> 1.2'),
                  Bundler::Dependency.new('dev_gem_3', '>= 0'),
                 ], g.dependencies)
  end

end
