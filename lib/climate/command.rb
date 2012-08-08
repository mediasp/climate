module Climate

  #
  # A {Command} is a unit of work, intended to be invoked from the command line.  It should be
  # extended to either do something itself by implementing run, or just be
  # there as a conduit for subcommands to do their work.
  #
  # See {ParsingMethods} for details on how to specify options and arguments
  #
  class Command

    class << self
      include ParsingMethods

      # Create an instance of this command class and run it against the given
      # arguments
      # @param [Array<String>] argv A list of arguments, ARGV style
      # @param [Hash] options see {#initialize}
      def run(argv, options={})
        begin
          instance = new(argv, options)
        rescue Trollop::HelpNeeded
          raise HelpNeeded.new(self)
        end

        if subcommands.empty?
          begin
            instance.run
          rescue Climate::CommandError => e
            # make it easier on users
            e.command_class = self if e.command_class.nil?
            raise
          end
        else
          find_and_run_subcommand(instance, options)
        end
      end

      def ancestors(exclude_self=false)
        our_list = exclude_self ? [] : [self]
        parent.nil?? our_list : parent.ancestors + our_list
      end

      # Supply a name for this command, or return the existing name
      def name(name=nil)
        @name = name if name
        @name
      end

      # because we've extended Class.name, we expose the original method
      # under another name
      # FIXME: surely there is a saner way of doing this?
      def class_name
        Class.method(:name).unbind.bind(self).call
      end

      # Register this class as being a subcommand of another {Command} class
      # @param [Command] parent_class The parent we hang off of
      def subcommand_of(parent_class)
        raise DefinitionError, 'can not set subcommand before name' unless @name
        parent_class.add_subcommand(self)
      end

      # Set the description for this command
      # @param [String] string Description/Banner/Help text
      def description(string=nil)
        if string
          @description = string
        else
          @description
        end
      end

      # Call this during class definition time if you don't want any of the
      # usual command line parsing to happen
      def disable_parsing
        @parsing_disabled = true
      end

      # Returns true if parsing is disabled
      attr_accessor :parsing_disabled

      # Set the parent of this command
      attr_accessor :parent

      def add_subcommand(subcommand)
        if cli_arguments.empty?
          subcommands << subcommand
          subcommand.parent = self
          stop_on(subcommands.map(&:name))
        else
          raise DefinitionError, 'can not mix subcommands with arguments'
        end
      end

      def arg(*args)
        if subcommands.empty?
          super(*args)
        else
          raise DefinitionError, 'can not mix subcommands with arguments'
        end
      end

      def has_subcommands? ; not subcommands.empty?   ; end
      def subcommands ; @subcommands ||= [] ; end

      private

      def find_and_run_subcommand(parent, options)
        command_name, *arguments = parent.leftovers

        if command_name.nil?
          raise MissingArgumentError.new("command #{parent.class.name}" +
            " expects a subcommand as an argument", parent)
        end

        found = subcommands.find {|c| c.name == command_name }

        if found
          found.run(arguments, options.merge(:parent => parent))
        else
          raise UnknownCommandError.new(command_name, parent)
        end
      end

    end

    # Create an instance of this command to be run.  You'll probably want to use
    # {Command.run}
    # @param [Array<String>] arguments ARGV style arguments to be parsed
    # @option options [Command] :parent The parent command, made available as {#parent}
    # @option options [IO] :stdout stream to use as stdout, defaulting to `$stdout`
    # @option options [IO] :stderr stream to use as stderr, defaulting to `$stderr`
    # @option options [IO] :stdin stream to use as stdin, defaulting to `$stdin`
    def initialize(argv, options={})
      @argv = argv.clone
      @parent = options[:parent]

      @stdout = options[:stdout] || $stdout
      @stderr = options[:stderr] || $stderr
      @stdin =  options[:stdin]  || $stdin

      if ! self.class.parsing_disabled
        @arguments, @options, @leftovers = self.class.parse(argv)
      end
    end

    # @return [Array]
    # The original list of unparsed argv style arguments that were given to
    # the command
    attr_accessor :argv

    # @return [Hash]
    # Options that were parsed from the command line
    attr_accessor :options

    # @return [Hash]
    # Arguments that were given on the command line
    attr_accessor :arguments

    # @return [Array]
    # Unparsed arguments, usually for subcommands
    attr_accessor :leftovers

    # @return [Command]
    # The parent command, or nil if this is not a subcommand
    attr_accessor :parent

    # @return [IO]
    # a possibly redirected stream
    attr_accessor :stdout, :stderr, :stdin

    def ancestor(ancestor_class, include_self=true)
      if include_self && self.class == ancestor_class
        self
      elsif parent.nil?
        raise "no ancestor exists: #{ancestor_class}"
        nil
      else
        parent.ancestor(ancestor_class)
      end
    end

    # Run the command, must be implemented by all commands that are not parent
    # commands (leaf commands)
    def run
      raise NotImplementedError, "Leaf commands must implement a run method"
    end
  end
end
