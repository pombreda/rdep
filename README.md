rdep
====

`rdep` is a simple gem / command line tool that will print the dependencies of a ruby project.
`rdep` is still under active development. There are bugs. Pull requests welcome :)
See also: https://github.com/sourcegraph/pydep

__WARNING: `rdep` may execute a project's .gemspec or `Gemfile`. Do not run on untrusted code.__

Install
-----
```
gem install rdep
```

Usage
-----

```
rdep -h  # print out options
rdep <src-directory>  # run pydep on project directory (should contain *.gemspec or Gemfile)
```

Additional requirements
-----------------------
- RubyGems (`gem`)
