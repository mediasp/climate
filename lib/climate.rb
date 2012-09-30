require 'trollop'

module Climate

  def self.with_standard_exception_handling(options={}, &block)
    error_messages = {
      UnexpectedArgumentError => 'Unknown argument',
      UnknownCommandError => 'Unknown command',
      MissingArgumentError => 'Missing argument',
      ConflictingOptionError => 'Conflicting options given'
    }

    begin
      yield
    rescue ExitException => e
      # exit silently if there is no error message to print out
      $stderr.puts(e.message) if e.has_message?
      exit(e.exit_code)
    rescue HelpNeeded => e
      print_usage(e.command_class, options)
      exit(0)
    rescue ParsingError => e
      $stderr.puts(error_messages[e.class] + ": #{e.message}")
      print_usage(e.command_class, options)
      exit(1)
    rescue => e
      $stderr.puts("Unexpected error: #{e.class.name} - #{e.message}")
      $stderr.puts(e.backtrace)
      exit(2)
    end
  end

  def self.print_usage(command_class, options={})
    help = Help.new(command_class)

    help.print(options)
  end

  def run(&block)
  end
end

require 'climate/errors'
require 'climate/parser'
require 'climate/command'
require 'climate/help'
require 'climate/script'
