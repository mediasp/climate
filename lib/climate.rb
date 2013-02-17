require 'trollop'

module Climate

  def self.error_messages
    error_messages = {
      UnexpectedArgumentError =>
      proc {|e| "Unknown argument: #{e}" },
      UnknownCommandError =>
      proc {|e| "Unknown command '#{e}': #{e.command_class.ancestors.map(&:command_name).join(' ')} expects one of: #{e.command_class.subcommands.map(&:command_name).join(' ')}" },
      MissingArgumentError =>
      proc {|e| "Missing argument: #{e.message}" },
      MissingSubcommandError =>
      proc {|e| "Missing argument: #{e.command_class.ancestors.map(&:command_name).join(' ')} expects one of: #{e.command_class.subcommands.map(&:command_name).join(' ')}" },
      ConflictingOptionError =>
      proc {|e| "Conflicting options given: #{e}" }
    }
  end

  def self.with_standard_exception_handling(options={}, &block)
    begin
      yield
    rescue => e
      exit handle_error(e, options)
    end
  end

  # extracted for stubbing/overriding without having to do it globally
  def self.stderr ; $stderr ; end
  def self.stdout ; $stdout ; end

  def self.handle_error(e, options)
    case e
    when ExitException
      # exit silently if there is no error message to print out
      stderr.puts(e.message) if e.has_message?
      e.exit_code
    when HelpNeeded
      help(e.command_class).print(options)
      0
    when ParsingError
      stderr.puts(error_messages[e.class].call(e))
      help(e.command_class).print_usage
      1
    else
      stderr.puts("Unexpected error: #{e.class.name} - #{e.message}")
      stderr.puts(e.backtrace)
      2
    end
  end

  def self.help(command_class)
    Help.new(command_class)
  end

  def self.print_usage(command_class, options={})
    help(command_class).print_usage(options)
  end

  def run(&block)
  end
end

require 'climate/errors'
require 'climate/parser'
require 'climate/command'
require 'climate/help'
require 'climate/script'
