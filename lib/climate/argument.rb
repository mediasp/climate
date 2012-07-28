module Climate
  class Argument

    attr_reader :name
    attr_reader :description

    def initialize(name, description, options={})
      @name        = name
      @description = description
      @required    = options.fetch(:required, true)
      @multi       = options.fetch(:multi, false)
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
