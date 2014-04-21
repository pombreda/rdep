require 'rubygems'
require 'bundler'
require 'net/http'
require 'json'
require 'tmpdir'

module RDep

  def self.load_gemspec(gemspecPath)
    Gem::Specification.load(gemspecPath)
  end

  def self.load_gemfile(gemfilePath)
    gemfilePathname = Pathname.new(gemfilePath)

    wd = Dir.pwd
    Dir.chdir(gemfilePathname.parent)
    builder = Bundler::Dsl.new
    builder.eval_gemfile(gemfilePathname.basename)
    Dir.chdir(wd)

    return builder
  end

  def self.gemspec_from_gem_name(gem, reqs)
    reqs_str = reqs.join(',')
    wd = Dir.pwd
    Dir.mktmpdir("rdep") do |d|
      Dir.chdir(d)
      system "gem fetch #{gem} -v '#{reqs_str}'"
      system "gem unpack #{gem}"
      Dir.chdir(wd)
      gemspecs = Dir.glob("#{d}/#{gem}*/*.gemspec")

      if gemspecs.length != 1
        return nil
      end
      return load_gemspec(gemspecs[0])
    end
  end

  @@vcs_url_patterns = [
                      /(https?\:\/\/github\.com\/[^\/]+\/[^\/]+)(?:\/.*)?/,
                      /(https?\:\/\/bitbucket\.org\/[^\/]+\/[^\/]+)(?:\/.*)?/,
                     ]

  # Accepts gem name. Returns source code URI, nil if none present
  def self.fetch_source_url(gem)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem}.json")
    resp = Net::HTTP.get(uri)
    j = JSON.parse(resp)

    if j['source_code_uri'] != nil
      return j['source_code_uri']
    end

    @@vcs_url_patterns.each do |reg|
      match = reg.match(j['homepage_uri'])
      if match != nil && match.length >= 2
        return match[1]
      end
    end

    return nil
  end

  def self.metadata(project_dir)
    gemspecs = Dir.glob(File.join(project_dir, '*.gemspec'))
    gemfile = File.join(project_dir, 'Gemfile')

    if gemspecs.length > 1
      raise "Found more than one .gemspec file: #{gemspecs}"
    end

    if gemspecs.length == 1
      gemspec = RDep::load_gemspec(gemspecs[0])
      {
        name: gemspec.name,
        version: gemspec.version,
        dependencies: gemspec.dependencies.map {|d|
          {
            name: d.name,
            requirements: d.requirements_list,
            source_url: fetch_source_url(d.name),
          }
        },
      }
    elsif File.exists?(gemfile)
      gemfile_info = RDep::load_gemfile(gemfile)
      {
        name: nil,
        version: nil,
        dependencies: gemfile_info.dependencies.map {|d|
          {
            name: d.name,
            requirements: d.requirements_list,
            source_url: fetch_source_url(d.name),
          }
        },
      }
    else
      nil
    end
  end

  def self.run(args)
    metadata = RDep::metadata(args[0])
    puts JSON.dump(metadata)
  end
end

if __FILE__ == $0
  RDep::run(ARGV)
end
