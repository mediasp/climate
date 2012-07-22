begin
  require 'erubis'
rescue LoadError => e
  $stderr.puts("erubis gem is required for man output")
  exit 1
end

class Climate::Help
  # can produce a troff file suitable for man
  class Man

    # Eat my own dog food
    class Script < Climate::Command
      name 'man'
      description 'Creates man/nroff output for a command'

      arg :command_class, "name of class that defines the command, i.e. Foo::Bar::Command",
      :type => :string, :required => true

      opt :out_file, "Name of a file to write nroff output to.  Defaults to stdout",
      :type => :string, :required => false


      def run
        out_file = (of = options[:out_file]) && File.open(of, 'w') || $stdout

        command_class = arguments[:command_class].split('::').
          inject(Object) {|m,v| m.const_get(v) }

        Man.new(command_class, :output => out_file).print
      end
    end

    class Presenter

      def self.proxy(method_name)
        define_method(method_name) do
          @command_class.send(method_name)
        end
      end

      def initialize(command_class)
        @command_class = command_class
      end

      attr_reader :command_class

      public :binding

      def full_name
        stack = []
        command_ptr = command_class
        while command_ptr
          stack.unshift(command_ptr.name)
          command_ptr = command_ptr.parent
        end

        stack.join(' ')
      end

      def short_name
        command_class.name
      end

      def date         ; Date.today.strftime('%b, %Y') ; end

      proxy :has_subcommands?
      proxy :cli_options
      proxy :cli_arguments
      proxy :has_options?
      proxy :has_arguments?

      def paragraphs
        command_class.description.split("\n\n")
      end

      def short_description
        command_class.description.split(".").first
      end

      def subcommands
        command_class.subcommands.map {|c| self.class.new(c) }
      end
    end

    attr_reader :command_class

    def initialize(command_class, options={})
      @command_class = command_class
      @output = options[:output] || $stdout
    end

    def print
      template = Erubis::Eruby.new(File.read(File.join(File.dirname(__FILE__), 'man.erb')))
      presenter = Presenter.new(command_class)
      @output.puts(template.result(presenter.binding))
    end

  end
end
