module Climate
  class Argument

    attr_reader :name
    attr_reader :description
    attr_reader :default

    def initialize(name, description, options={})
      @name        = name
      @description = description
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
end
