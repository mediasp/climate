module Climate
  class Help

    attr_reader :command_class

    def initialize(command_class, options={})
      @command_class = command_class
      @indent = 0
      @output = options[:output] || $stdout
    end

    def print
      print_usage
      print_description
      print_options if command_class.has_options? || command_class.has_arguments?
      print_subcommands if command_class.has_subcommands?
    end

    def print_usage
      ancestor_list = command_class.ancestors.map(&:name).join(' ')
      opts_usage = command_class.cli_options.map {|opt| opt.usage }.join(' ')
      args_usage =
        if command_class.has_subcommands?
          "<subcommand> [<arguments>]"
        else
          command_class.cli_arguments.map {|arg| arg.usage }.join(' ')
        end
      puts("usage: #{ancestor_list} #{opts_usage} #{args_usage}")
    end

    def print_description
      newline
      puts "Description"
      indent do
        puts(command_class.description)
      end
    end

    def print_subcommands
      newline
      puts "Available subcommands:"
      indent do
        command_class.subcommands.each do |subcommand_class|
          puts "#{subcommand_class.name}"
        end
      end
    end

    def print_options
      newline
      puts "Options"
      indent do

        if command_class.has_subcommands?
          puts "<subcommand>"
          indent do
            puts "Name of subcommand to execute"
          end
          newline
          puts "<arguments>"
          indent do
            puts "Arguments for subcommand"
          end
          newline
        end

        command_class.cli_arguments.each do |argument|
          puts "<#{argument.name}>"
          indent do
            puts argument.description
          end
          newline
        end

        command_class.cli_options.each do |option|
          puts "#{option.usage(:with_long => true, :hide_optional => true, :separator => ', ')}"
          indent do
            puts option.description
          end
          newline
        end
      end
    end

    def indent(&block)
      @indent += 1
      yield if block_given?
      unindent if block_given?
    end

    def unindent
      @indent -= 1
    end

    def spaces
      @indent * 4
    end

    def newline
      @output.puts("\n")
    end

    def puts(string='')
      string.split("\n").each do |line|
        @output.puts((' ' * spaces) + line)
      end
    end

    private

    # stolen from trollop
    def width #:nodoc:
      @width ||= if $stdout.tty?
                   begin
                     require 'curses'
                     Curses::init_screen
                     x = Curses::cols
                     Curses::close_screen
                     x
                   rescue Exception
                     80
                   end
                 else
                   80
                 end
    end

    def wrap(string)

      string.split("\n\n").map { |para|

        words = para.split(/[\n ]/)
        words[1..-1].inject([words.first]) { |m, v|
          new_last_line = m.last + " " + v

          if new_last_line.length <= (width - spaces)
            m[0...-1] + [new_last_line]
          else
            m + [v]
          end
        }.join("\n")

      }.join("\n\n")
    end


  end
end
