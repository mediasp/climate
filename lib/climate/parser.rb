module Climate

  module ParsingMethods

    def arg(*args)
      raise DefinitionError, "can not define a required argument after an " +
        "optional one" if cli_arguments.any?(&:optional?)

      cli_arguments << Argument.new(*args)
    end

    def opt(*args)
      cli_options << Option.new(*args)
    end

    def stop_on(args)
      @stop_on = args
    end

    def trollop_parser
      parser = Trollop::Parser.new

      parser.stop_on @stop_on

      if cli_arguments.size > 0
        parser.banner ""
        max_length = cli_arguments.map { |h| h.name.to_s.length }.max
        cli_arguments.each do |argument|
          parser.banner("  " + argument.name.to_s.rjust(max_length) + " - #{argument.description}")
        end
      end

      parser.banner ""
      cli_options.each do |option|
        option.add_to(parser)
      end
      parser
    end

    def help_banner(out=$stdout)
      trollop_parser.educate(out)
    end

    def check_arguments(args, command=self)

      if args.size > cli_arguments.size
        raise UnexpectedArgumentError.new("#{args.size} for #{cli_arguments.size}", command)
      end

      cli_arguments.zip(args).map do |argument, arg_value|
        if argument.required? && (arg_value.nil? || arg_value.empty?)
          raise MissingArgumentError.new(argument.name, command)
        end

        # no arg given is different to an empty arg
        if arg_value.nil?
          {}
        else
          {argument.name => arg_value}
        end
      end.inject {|a,b| a.merge(b) } || {}
    end

    def parse(arguments, command=self)
      parser = self.trollop_parser
      begin
        options = parser.parse(arguments)
      rescue Trollop::CommandlineError => e
        if (m = /unknown argument '(.+)'/.match(e.message))
          raise UnexpectedArgumentError.new(m[1], command)
        else
          raise
        end
      end

      # it would get weird if we allowed arguments alongside options, so
      # lets keep it one or t'other
      arguments, leftovers =
        if @stop_on
          [[], parser.leftovers]
        else
          [self.check_arguments(parser.leftovers), []]
        end

      [arguments, options, leftovers]
    end

    def cli_options   ; @cli_options ||= []   ; end
    def cli_arguments ; @cli_arguments ||= [] ; end

    def has_options? ;     not cli_options.empty?   ; end
    def has_arguments? ;   not cli_arguments.empty? ; end

  end

  class Parser
    include ParsingMethods

    def initialize(&block)
      instance_eval(&block) if block_given?
    end
  end
end
