# Climate

Yet another bloody CLI library for ruby, based on, and inspired by, the
magnificence that is trollop, with more of a mind for building up a git-like
CLI to access your application without enforcing a particular style of project
structure.

Designed for both simple uses, as well as more complicated use cases

# Easy

Useful for one-shot scripts

    Climate.run do
      banner "Do something arbitrary to a file"

      opt :log, "Whether to log to stdout" :default => false
      arg :path "Path to input file"

      def run
        file = File.open(arguments[:path], 'r')
        puts("loaded #{file}") if options[:log]
      end
    end

# Medium

This style is more intended for embedding a CLI in to your existing application

    class Parent < Climate::Command
      banner "App that does it all, yet without fuss"
      opt    :log, "Whether to log to stdout" :default => false
    end

    class Arbitrary < Climate::Command
      subcommand 'arbitrary', Parent
      banner "Do something arbitrary to a file"
      arg    :path "Path to input file"

      def run
        file = File.open(arguments[:path], 'r')
        puts("loaded #{file}") if parent.options[:log]
      end
    end

    Climate.with_standard_exception_handling do
      Parent.run(ARGV)
    end

ruby -rclimate example.rb --log /tmp/file

or

ruby -rclimate example.rb --help
