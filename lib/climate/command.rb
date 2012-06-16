module Climate
  class Command

    module ClassMethods

      def cli_argument(*args)
        cli_arguments << Argument.new(*args)
      end

      def cli_option(*args)
        cli_options << Option.new(*args)
      end

      def command_name
        self.name.split("::").last.gsub(/(.)([A-Z])/, '\1_\2').downcase
      end

      def usage_line
        pp_args = cli_arguments.map {|arg| arg.formatted }
        "Usage: msp_release #{command_name} #{pp_args.join(' ')}"
      end

      def trollop_parser
        parser = Trollop::Parser.new
        parser.banner self.description

        if cli_arguments.size > 0
          parser.banner ""
          max_length = cli_arguments.map { |h| h.name.to_s.length }.max
          cli_arguments.each do |argument|
            parser.banner("  " + argument.name.to_s.rjust(max_length) + " - #{argument.description}")
          end
        end

        parser.banner ""
        cli_options.each do |option|
          parser.opt(option.name, option.description, option.extra)
        end
        parser
      end

      def check_arguments(args)

        if args.size > cli_arguments.size
          $stderr.puts(usage_line)
          raise ExitException, "Too many arguments supplied to command #{command_name}"
        end

        cli_arguments.zip(args).map do |argument, arg_value|
          if argument.required? && (arg_value.nil? || arg_value.empty?)
            $stderr.puts("Error: you must supply an argument for #{argument.name}")
            $stderr.puts(usage_line)
            raise ExitException, "Not enough arguments supplied to command #{command_name}"
          end
          {argument.name => arg_value}
        end.inject {|a,b| a.merge(b) }
      end

      private

      # kept private to prevent mutation
      def cli_options   ; @cli_options ||= []   ; end
      def cli_arguments ; @cli_arguments ||= [] ; end

    end

    class << self
      include ClassMethods
    end

    def initialize(arguments)
      parser = self.class.trollop_parser
      @options = parser.parse(arguments)
      @arguments = self.class.check_arguments(parser.leftovers)
    end

    attr_accessor :options, :arguments

  end
end
