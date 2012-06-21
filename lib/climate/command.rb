module Climate

  #
  # A {Command} is a unit of work, intended to be invoked from the command line.  It should be
  # extended to either do something itself by implementing run, or just be
  # there as a conduit for subcommands to do their work.
  #
  # See {ParsingMethods} for details on how to specify options and arguments
  #
  class Command

    class << self
      include ParsingMethods

      # Create an instance of this command class and run it against the given
      # arguments
      # @param [Array<String>] arguments A list of arguments, ARGV style
      # @param [Command] parent The parent command, made available as {#parent}
      def run(arguments, parent=nil)
        instance = new(arguments, parent)

        if subcommands.empty?
          instance.run
        else
          find_and_run_subcommand(instance)
        end
      end

      # Register this class as being a subcommand of another {Command} class
      # @param [String] name The name of the subcommand
      # @param [Command] parent_class The parent we hang off of
      def subcommand(name, parent_class)
        parent_class.add_subcommand(name, self)
      end

      def add_subcommand(name, subcommand)
        if cli_arguments.empty?
          subcommands << [name, subcommand]
          stop_on(subcommands.map(&:first))
        else
          raise DefinitionError, 'can not mix subcommands with arguments'
        end
      end

      def arg(*args)
        if subcommands.empty?
          super(*args)
        else
          raise DefinitionError, 'can not mix subcommands with arguments'
        end
      end

      private

      def find_and_run_subcommand(parent)
        command_name, *arguments = parent.leftovers
        _, found = subcommands.find {|n,c| n == command_name }

        if found
          found.run(arguments, parent)
        else
          raise Climate::UnknownCommandError, command_name
        end
      end

      def subcommands ; @subcommands ||= [] ; end
    end

    # Create an instance of this command to be run.  You'll probably want to use
    # {Command.run}
    # @param [Array<String>] arguments ARGV style arguments to be parsed
    # @param [Command] parent
    def initialize(arguments, parent=nil)
      @parent = parent
      @arguments, @options, @leftovers = self.class.parse(arguments)
    end

    # @return [Hash]
    # Options that were parsed
    attr_accessor :options

    # @return [Hash]
    # Arguments that were given
    attr_accessor :arguments

    # @return [Array]
    # Unparsed arguments, usually for subcommands
    attr_accessor :leftovers

    # @return [Command]
    # The parent command, or nil if this is not a subcommand
    attr_accessor :parent

  end
end
