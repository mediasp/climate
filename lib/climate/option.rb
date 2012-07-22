module Climate
  class Option

    attr_reader :name
    attr_reader :description
    attr_reader :options

    def initialize(name, description, options={})
      @name        = name
      @description = description
      @options     = options
    end

    def type    ; spec[:type]    ; end
    def long    ; spec[:long]    ; end
    def short   ; spec[:short]   ; end
    def default ; spec[:default] ; end

    def optional? ; spec.has_key?(:default) ; end
    def required? ; ! optional?             ; end

    def spec ; @specs ||= parser.specs[@name] ; end

    def parser
      @parser ||= Trollop::Parser.new.tap {|p| add_to(p) }
    end

    def long_usage
      type == :flag ? "--#{long}" : "--#{long}=<#{type}>"
    end

    def short_usage
      short && (type == :flag ? "-#{short}" : "-#{short}<#{type}>")
    end

    def usage(options={})
      help = short_usage || long_usage

      if options[:with_long] && (long_usage != help)
        help = [help, long_usage].compact.join(options.fetch(:separator, '|'))
      end

      if optional? && !options.fetch(:hide_optional, false)
        "[#{help}]"
      else
        help
      end
    end

    def add_to(parser)
      parser.opt(@name, @description, @options)
    end
  end
end
