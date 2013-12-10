# Climate

Yet another bloody CLI library for ruby, based on, and inspired by, the
magnificence that is trollop, with more of a mind for building up a git-like
CLI to access your application without enforcing a particular style of project
structure.

Designed for both simple and more complex cases.

 - Embed a CLI in to your application
 - Builds on trollop, a refreshingly sane option parsing library
 - N-levels of subcommands
 - Nice help output

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

# rack-middleware like filtering

Quite often in commands you might want some shared logic to do with setting up
or tearing down an environment for your child commands.  For instance, you might
want to setup an application environment, start a database transaction, or check
some arguments are semantically correct in a way that is common based on a parent
command, i.e:

    class Parent < Climate::Command('parent')
      def run(chain)
        setup_logger
        begin
          chain.run
        rescue => e
          logger.error("oh noes!")
          raise
        end
      end
    end

    class Child < Climate::Command('child')
      subcommand_of Parent

      def run
        if all_ok?
          do_the_thing
        else
          raise 'it went badly'
        end
      end
    end

The `run` method on non-leaf commands can also omit the chain argument, in which
case you are not responsible for calling the next link in the chain, but you can
still do some setup.

# Accessing your parent command at execution time

In the case where you have some parent command that gets all the top level
options for your application, (i.e. config location, log mode), you may need to
access this from your child commands.  You can do this with the `ancestor`
instance method, or by proxying the method to your child class with
`expose_ancestor_method`.  For example:

    class Parent < Climate::Command('parent')
      def useful_stuff ; end
      def handy_service ; end
    end

    class Child < Climate::Command('child')
      subcommand_of Parent

      expose_ancestor_method Parent, :handy_service

      def run
        # finds the parent command instance so you can interrogate it
        ancestor(Parent).useful_stuff

        # handy_service was defined as an instance method using the
        # #expose_ancestor_method above, but ultimately it is syntactic sugar
        # for the above
        handy_service.send_the_things
      end
    end
