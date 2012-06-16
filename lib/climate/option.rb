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
  end
end
