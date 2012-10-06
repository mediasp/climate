# Climate

Yet another bloody CLI library for ruby, based on, and inspired by, the
magnificence that is trollop, with more of a mind for building up a git-like
CLI to access your application without enforcing a particular style of project
structure.

Designed for both simple and more complex cases.

# Easy

Useful for one-shot scripts:

    #! /usr/bin/env climate
    # the shebang is optional, you can just load the script with
    # `ruby -r rubygems -r climate script.rb`
    extend Climate::Script
    description "Do something arbitrary to a file"

    opt :log, "Whether to log to stdout" :default => false
    arg :path "Path to input file"

    def run
      file = File.open(arguments[:path], 'r')
      puts("loaded #{file}") if options[:log]
    end

# Medium

This style is intended for embedding a CLI in to your existing application.

    class Parent < Climate::Command('thing')
      description "App that does it all, yet without fuss"
      opt    :log, "Whether to log to stdout" :default => false
    end

    class Arbitrary < Climate::Command
      set_name 'arbitrary'
      subcommand_of, Parent
      description "Do something arbitrary to a file"
      arg    :path "Path to input file"

      def run
        file = File.open(arguments[:path], 'r')
        puts("loaded #{file}") if parent.options[:log]
      end
    end

    Climate.with_standard_exception_handling do
      Parent.run(ARGV)
    end

There is a working example, `example.rb` that you can test out with

    ruby -rrubygems -rclimate example.rb --log /tmp/file

or

    ruby -rrubygems -rclimate example.rb --help
