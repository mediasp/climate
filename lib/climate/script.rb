module Climate

  # Module that you can extend any object with to turn it in to a climate
  # script.  See the readme for intended usage, but follows the same pattern
  # as the command, with the exception that it does not allow subcommands
  module Script

    def self.extended(othermodule)
      if @included.nil?
        @included = true
        at_exit do
          Climate.with_standard_exception_handling do
            othermodule.send(:parse_argv)
            othermodule.send(:run)
          end
        end
      end
    end

    include ParsingMethods
    # Set the description for this script
    # @param [String] string Description/Banner/Help text
    def description(string=nil)
      if string.nil?
        @description
      else
        @description = string
      end
    end

    def parse_argv
      @arguments, @options, @leftovers = self.parse(ARGV)
    end

    attr_reader :arguments, :options, :leftovers

    def ancestors ; [self] ; end
    def name ; File.basename($PROGRAM_NAME) ; end

    def has_subcommands? ; false ; end

  end
end
