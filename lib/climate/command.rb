module Climate
  class Command

    class << self
      include ParsingMethods

      def run(arguments)
        command = new(arguments)

        if subcommands.empty?
          command.run
        else
          find_and_run_subcommand(command.leftovers)
        end
      end

      def find_subcommand(leftovers)
      end

      def parent
        @parent = true
      end

      def add_subcommand(name, subcommand)
        if cli_arguments.empty?
          subcommands << [name, subcommand]
          stop_on(subcommands.map(&:first))
        else
          raise DefinitionError 'can not mix subcommands with arguments'
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

    def initialize(arguments)
      @arguments, @options, @leftovers = self.class.parse(arguments)
    end

    attr_accessor :options, :arguments, :leftovers

  end
end
