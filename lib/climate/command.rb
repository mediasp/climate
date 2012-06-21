module Climate
  class Command

    class << self
      include ParsingMethods

      def run(arguments, parent=nil)
        instance = new(arguments, parent)

        if subcommands.empty?
          instance.run
        else
          find_and_run_subcommand(instance)
        end
      end

      def find_and_run_subcommand(parent)
        command_name, *arguments = parent.leftovers
        _, found = subcommands.find {|n,c| n == command_name }

        if found
          found.run(arguments, parent)
        else
          raise Climate::UnknownCommandError, command_name
        end
      end

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

      def subcommands ; @subcommands ||= [] ; end
    end

    def initialize(arguments, parent)
      @parent = parent
      @arguments, @options, @leftovers = self.class.parse(arguments)
    end

    attr_accessor :options, :arguments, :leftovers, :parent

  end
end
