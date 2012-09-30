require 'climate'
require 'yaml'

module Example

  class Parent < Climate::Command('example')
    description <<DESC
Example app to show usage of subcommands.

Implements a contrived cli for querying and updating a yaml config file.
DESC

    opt  :log,         'Whether to log to stderr, defaults to {default}', :default => false
    opt  :config_file, 'Path to config file',      :type => :string,
    :short => 'f', :required => true

    opt  :create,      'Create the config file if it is missing, defaults to {default}',
    :default => false

    opt :value,        'Override a config file value on the command line.  ' +
      'Separate keys and values with an equals sign, so --value key=value',
    :multi => true, :type => :string

  end

  module Common

    def log(message)
      stderr.puts("log: #{message}") if ancestor(Parent).options[:log]
    end

    def config_yaml
      parent = ancestor(Parent)
      filename = parent.options[:config_file]

      if not File.exists?(filename)
        log("Creating empty config file #{filename}")
        if parent.options[:create]
          File.open(filename, 'w') {|f| YAML.dump({}, f) }
        else
          raise Climate::ExitException.new("No config file: #{filename}")
        end
      end

      log("Loading config from #{filename}")
      YAML.load_file(filename).tap do |values|
        cli_values = ancestor(Parent).options[:value]
        cli_values.map {|v| v.split('=') }.each {|k,v| values[k] = v }
      end
    end

    def save_config(hash)
      parent = ancestor(Parent)
      filename = parent.options[:config_file]

      log("Saving config to #{filename}")
      File.open(filename, 'w') {|f| YAML.dump(hash, f) }
    end
  end

  class Test < Climate::Command('test')
    include Common
    subcommand_of Parent

    description 'Test if a config value matches, exiting with 0 if it matches, 2 if it is less than, 3 if it is more than, and 4 if there is no key with that value.  1 is reserved for unexpected errors.'

    arg :key, 'Name of the config key to check'
    arg :value, 'Config value to be tested'

    def run
      yaml = config_yaml

      exit(4) unless yaml.has_key?(arguments[:key])

      expected_value = yaml[arguments[:key]]

      case arguments[:value] <=> expected_value
      when 0 then exit(0)
      when -1 then exit(2)
      when 1 then exit(3)
      end
    end
  end

  class Show < Climate::Command('show')
    include Common
    subcommand_of Parent

    description <<DESC
Show configuration values.

Here is another paragraph explaining that you can show a value or multiple
values that exist in the config file by supplying or not supplying an argument
DESC

    arg :keys, 'one or more config keys to show', :required => false,
    :multi => true

    opt :json, 'output as json'
    opt :text, 'output as plain text', :default => true

    conflicts :json, :text

    def run
      yaml = config_yaml

      keys = arguments[:keys]
      keys = yaml.keys.sort if keys.empty?

      if options[:json]
        stdout.puts('{')
        keys.each do |key|
          escaped = yaml[key].to_s.gsub('"', '\"')
          stdout.puts("  \"#{key}\" : \"#{escaped}\"")
        end
        stdout.puts('}')
      elsif options[:text]
        keys.each do |key|
          stdout.puts("#{key}: #{yaml[key]}")
        end
      end
    end
  end

  class Set < Climate::Command('set')
    include Common
    subcommand_of Parent
    description <<DESC
Set a configuration value.

This opens the config file and sets a value to it, or clears a value if you do
not supply a second argument.
DESC
    arg :key, 'config key to set'
    arg :value, 'value to set', :required => false

    def run
      yaml = config_yaml

      if arguments.has_key?(:value)
        yaml[arguments[:key]] = arguments[:value]
      else
        yaml.delete(arguments[:key])
      end

      save_config(yaml)
    end
  end

  class Echo < Climate::Command('echo')
    include Common
    subcommand_of Parent

    description <<DESC
Contrived command that lets you view all args and options passed to it,
unparsed.
DESC

    disable_parsing

    def run
      raise Climate::HelpNeeded, self if argv.include?('-h')
      stdout.puts argv.inspect
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Climate.with_standard_exception_handling do
    Example::Parent.run(ARGV)
  end
end
