module Climate
  class Argument

    attr_reader :name
    attr_reader :description

    def initialize(name, description, options={})
      @name        = name
      @description = description
      @required    = options.fetch(:required, true)
    end

    def required? ; @required   ; end
    def optional? ; ! required? ; end

    def formatted
       required?? name.to_s.upcase : "[#{name.to_s.upcase}]"
    end
  end
end
