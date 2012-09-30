module Climate

  # Keeps the description munging code in one place
  module Described
    attr_reader :name

    def initialize(name, description, *rest)
      @name        = name
      @description = description
    end

    def description
      (@description || '').gsub(/\{default\}/, default.to_s)
    end
  end

  # Wraps the properties supplied to Trollop::Parser#opt for some OO over
  # engineered sweetness
  class Option
    include Described
    attr_reader :options

    def initialize(name, description, options={})
      @options     = options
      super
    end

    def type    ; spec[:type]    ; end
    def long    ; spec[:long]    ; end
    def short   ; spec[:short]   ; end
    def default ; spec[:default] ; end

    def optional? ; spec.has_key?(:default) ; end
    def required? ; ! optional?             ; end
    def multi?    ; spec[:multi]            ; end

    def spec ; @specs ||= parser.specs[@name] ; end

    def parser
      @parser ||= Trollop::Parser.new.tap {|p| add_to(p) }
    end

    def long_usage
      type == :flag ? "--[no-]#{long}" : "--#{long}=<#{type}>"
    end

    def short_usage
      short && (type == :flag ? "-#{short}" : "-#{short} <#{name}>")
    end

    def usage(options={})
      help = short_usage || long_usage

      if options[:with_long] && (long_usage != help)
        help = [help, long_usage].compact.join(options.fetch(:separator, '|'))
      end

      if optional? && !options.fetch(:hide_optional, false)
        "[#{help}]"
      elsif multi? && !options.fetch(:hide_optional, false)
        "[#{help}...]"
      else
        help
      end
    end

    def add_to(parser)
      parser.opt(@name, @description, @options)
    end
  end

  # argument definition is stored in these
  class Argument
    include Described
    attr_reader :default

    def initialize(name, description, options={})
      super
      @required    = options.fetch(:required, ! options.has_key?(:default))
      @multi       = options.fetch(:multi, false)
      @default     = options.fetch(:default, nil)
    end

    def required? ; @required   ; end
    def optional? ; ! required? ; end
    def multi?    ; @multi      ; end

    def usage
      string = "<#{name}>"
      string += '...' if multi?
      optional??  "[#{string}]" : string
    end
  end

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

    def conflicts(*args)
      conflicting_options << args
    end

    def trollop_parser
      Trollop::Parser.new.tap do |parser|
        parser.stop_on @stop_on

        cli_options.each do |option|
          option.add_to(parser)
        end

        conflicting_options.each do |conflicting|
          parser.conflicts(*conflicting)
        end
      end
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
        arg_value ||= argument.default
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
        elsif (m = /(.+) conflicts with (.+)/.match(e.message))
          raise ConflictingOptionError.new(e.message, command)
        else
          raise CommandError.new(e.message, command)
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

    def cli_options         ; @cli_options ||= []         ; end
    def cli_arguments       ; @cli_arguments ||= []       ; end
    def conflicting_options ; @conflicting_options ||= [] ; end

    def has_options? ;     not cli_options.empty?   ; end
    def has_arguments? ;   not cli_arguments.empty? ; end

    def has_argument?(name)
      cli_arguments.map(&:name).include?(name)
    end

    def has_required_argument?(name)
      cli_arguments.select(&:required?).map(&:name).include?(name)
    end

    def has_multi_argument?(name)
      cli_arguments.select(&:multi?).map(&:name).include?(name)
    end

  end

  class Parser
    include ParsingMethods

    def initialize(&block)
      instance_eval(&block) if block_given?
    end
  end
end
