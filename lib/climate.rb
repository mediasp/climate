require 'trollop'

module Climate

  def self.error_messages
    error_messages = {
      UnexpectedArgumentError => 'Unknown argument',
      UnknownCommandError => 'Unknown command',
      MissingArgumentError => 'Missing argument',
      ConflictingOptionError => 'Conflicting options given'
    }
  end

  def self.with_standard_exception_handling(options={}, &block)
    begin
      yield
    rescue => e
      exit handle_error(e, options)
    end
  end

  def self.handle_error(e, options)
    case e
    when ExitException
      # exit silently if there is no error message to print out
      $stderr.puts(e.message) if e.has_message?
      e.exit_code
    when HelpNeeded
      print_usage(e.command_class, options)
      0
    when ParsingError
      $stderr.puts(error_messages[e.class] + ": #{e.message}")
      print_usage(e.command_class, options)
      1
    else
      $stderr.puts("Unexpected error: #{e.class.name} - #{e.message}")
      $stderr.puts(e.backtrace)
      2
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
