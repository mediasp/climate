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

    def optional?
      spec.has_key?(:default)
    end

    def required? ; ! optional? ; end

    def parser
      @parser ||= Trollop::Parser.new.tap {|p| add_to(p) }
    end

    def spec
      @specs ||= parser.specs[@name]
    end

    def usage
      help =
        if type == :flag
          "-#{short}"
        else
          "-#{short}<#{type}>"
        end

      if optional?
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
