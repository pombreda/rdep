require 'rubygems'
require 'pathname'
require 'bundler'
require 'net/http'
require 'json'
require 'tmpdir'
require 'optparse'
require 'set'

module RDep

  # Loads and returns gemspec at path.
  def self.load_gemspec(gemspecPath)
    spec = nil
    no_warn {  # loading gem prints crap to stderr on error
      spec = Gem::Specification.load(gemspecPath)
    }
    spec
  end

  # Loads and returns gemfile at path.
  def self.load_gemfile(gemfilePath)
    gemfilePathname = Pathname.new(gemfilePath)

    wd = Dir.pwd
    Dir.chdir(gemfilePathname.parent)
    builder = Bundler::Dsl.new
    builder.eval_gemfile(gemfilePathname.basename)
    Dir.chdir(wd)

    return builder
  end

  # Returns gemspec for a gem specified by name.
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

  # Return metadata for project at project_dir (expects a *.gemspec or a Gemfile). Optionally include dependency info.
  def self.metadata(project_dir, incl_deps)
    gemspecs = Dir.glob(File.join(project_dir, '*.gemspec'))
    gemfile = File.join(project_dir, 'Gemfile')

    if gemspecs.length > 1
      raise "Found more than one .gemspec file: #{gemspecs}"
    end

    mdata = {}
    if gemspecs.length == 1
      gemspec = RDep::load_gemspec(gemspecs[0])
      mdata[:name] = gemspec.name
      mdata[:version] = gemspec.version
      if incl_deps
        mdata[:dependencies] = gemspec.dependencies.map {|d|
          {
            name: d.name,
            requirements: d.requirements_list,
            source_url: fetch_source_url(d.name),
          }
        }
      end
    elsif File.exists?(gemfile)
      gemfile_info = RDep::load_gemfile(gemfile)
      mdata[:name] = nil
      mdata[:version] = nil
      if incl_deps
        mdata[:dependencies] = gemfile_info.dependencies.map {|d|
          {
            name: d.name,
            requirements: d.requirements_list,
            source_url: fetch_source_url(d.name),
          }
        }
      end
    else
      mdata = nil
    end
    return mdata
  end

  # Scan toplevel_dir for all projects and return metadata for all of them. Optionally, include dependency info for each.
  def self.scan(toplevel_dir, incl_deps)
    project_dirs = Set.new
    add_project_dir = Proc.new {|f|
      project_dirs.add(File.dirname(f))
    }
    Dir.glob(File.join(toplevel_dir, '**', '*.gemspec')).each &add_project_dir
    Dir.glob(File.join(toplevel_dir, '**', 'config.ru')).each &add_project_dir
    Dir.glob(File.join(toplevel_dir, '**', 'Gemfile')).each &add_project_dir

    mdata = []
    project_dirs.each {|d|
      begin
        m = metadata(d, incl_deps)
        if m != nil
          m[:path] = Pathname.new(d).relative_path_from(Pathname.new(File.expand_path(toplevel_dir))).to_s
          mdata.push(m)
        end
      rescue
      end
    }
    return mdata
  end

  # rdep command
  def self.run(args)
    options = {incl_dep: true}
    optparser = OptionParser.new do |opts|
      opts.banner = "Usage: rdep [OPTIONS] <project-dir>"
      opts.on('-s', '--scan', 'Scan directory recursively for projects and print metadata for all of them.') do |scan|
        options[:scan] = scan
      end
      opts.on('-o', '--no-dep', "Omit dependency information (will run faster)") do |nodep|
        options[:incl_dep] = false
      end
    end
    optparser.parse!(args)

    if args.length != 1
      $stderr.puts optparser.help
      return
    end
    dir = args[0]

    if options[:scan]
      mdata = RDep::scan(dir, options[:incl_dep])
      puts JSON.dump(mdata)
    else
      mdata = RDep::metadata(dir, options[:incl_dep])
      puts JSON.dump(mdata)
    end
  end

  # Run a block with warnings disabled (don't pollute stderr)
  def self.no_warn
    v = $VERBOSE
    $VERBOSE = nil
    begin
      yield
    ensure
      $VERBOSE = v
    end
  end

end

if __FILE__ == $0
  RDep::run(ARGV)
end
