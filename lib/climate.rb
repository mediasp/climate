require 'trollop'

module Climate
  def self.with_standard_exception_handling(&block)
    begin
      yield
    rescue ExitException => e
      $stderr.puts(e.message)
      exit(e.exitcode)
    rescue HelpNeeded => e
      print_usage(e.command_class)
    rescue UnknownCommandError => e
      $stderr.puts("Unknown command: #{e.message}")
      print_usage(e.command_class)
    rescue MissingArgumentError => e
      $stderr.puts("Missing argument: #{e.message}")
      print_usage(e.command_class)
    rescue => e
      $stderr.puts("Unexpected error: #{e.message}")
      $stderr.puts(e.backtrace)
    end
  end

  def self.print_usage(command_class)
    Help.new(command_class).print
  end
end

require 'climate/errors'
require 'climate/argument'
require 'climate/option'
require 'climate/parser'
require 'climate/command'
require 'climate/help'
