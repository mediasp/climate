module Climate

  module ParsingMethods

    def arg(*args)
      arg = Argument.new(*args)

      raise DefinitionError, "can not define more arguments after a multi " +
        " argument" if cli_arguments.any?(&:multi?)

      raise DefinitionError, "can not define a required argument after an " +
        "optional one" if cli_arguments.any?(&:optional?) && arg.required?

      cli_arguments << arg
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

      cli_options.each do |option|
        option.add_to(parser)
      end
      parser
    end

    def parse_arguments(args, command=self)

      arg_list = cli_arguments

      if arg_list.none?(&:multi?) && args.size > arg_list.size
        raise UnexpectedArgumentError.new("#{args.size} for #{arg_list.size}", command)
      end

      # mung the last arguments to appear as one for multi args, this is fairly
      # ugly - thank heavens for unit tests
      if arg_list.last && arg_list.last.multi?
        multi_arg = arg_list.last
        last_args = args[(arg_list.size - 1)..-1] || []

        # depending on the number of args that were supplied, you may get nil
        # or an empty array because of how slicing works, either way we want nil
        # if no args were supplied so `required?` detection works below
        args = args[0...(arg_list.size - 1)] +
          [last_args.empty?? nil : last_args].compact
      end

      arg_list.zip(args).map do |argument, arg_value|

        if argument.required? && arg_value.nil?
          raise MissingArgumentError.new(argument.name, command)
        end

        # empty list is nil for multi arg
        arg_value = [] if argument.multi? && arg_value.nil?

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
        elsif (m = /option (.+) must be specified/.match(e.message))
          raise MissingArgumentError.new(m[1], command)
        else
          raise
        end
      end

      # it would get weird if we allowed arguments alongside options, so
      # lets keep it one or t'other
      arguments, leftovers =
        if @stop_on
          [{}, parser.leftovers]
        else
          [self.parse_arguments(parser.leftovers), []]
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
