require 'trollop'

module Climate
  def self.with_standard_exception_handling(&block)
    begin
      yield
    rescue ExitException => e
      $stderr.puts(e.message)
      exit(e.exit_code)
    rescue HelpNeeded => e
      print_usage(e.command_class)
      exit(0)
    rescue UnexpectedArgumentError => e
      $stderr.puts("Unknown argument: #{e.message}")
      print_usage(e.command_class)
      exit(1)
    rescue UnknownCommandError => e
      $stderr.puts("Unknown command: #{e.message}")
      print_usage(e.command_class)
      exit(1)
    rescue MissingArgumentError => e
      $stderr.puts("Missing argument: #{e.message}")
      print_usage(e.command_class)
      exit(1)
    rescue => e
      $stderr.puts("Unexpected error: #{e.class.name} - #{e.message}")
      $stderr.puts(e.backtrace)
      exit(2)
    end
  end

  def self.print_usage(command_class, options={})
    help = Help.new(command_class)

    help.print
  end

  def run(&block)
  end
end

require 'climate/errors'
require 'climate/argument'
require 'climate/option'
require 'climate/parser'
require 'climate/command'
require 'climate/help'
require 'climate/script'
