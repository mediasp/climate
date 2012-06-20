module Climate
  class Command

    class << self
      include ParsingMethods
    end

    def initialize(arguments)
      @arguments, @options = self.class.parse(arguments)
    end

    attr_accessor :options, :arguments

  end
end
