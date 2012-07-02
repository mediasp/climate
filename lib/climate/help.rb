module Climate
  class Help

    attr_reader :command_class

    def initialize(command_class, options={})
      @command_class = command_class
      @indent = 0
    end

    def print(output=$stdout)
      @output = output
      ancestor_list = command_class.ancestors.map(&:name).join(' ')
      opts_usage = command_class.cli_options.map {|opt| opt.usage }.join(' ')
      args_usage =
        if command_class.has_subcommands?
          "<subcommand> [<arguments>]"
        else
          command_class.cli_arguments.map {|arg| arg.usage }.join(' ')
        end
      puts("usage: #{ancestor_list} #{opts_usage} #{args_usage}")

      if command_class.has_subcommands?
        puts
        puts "Available subcommands:"
        indent
        command_class.subcommands.each do |subcommand_class|
          puts "#{subcommand_class.name}"
        end
      end
    end

    def indent
      @indent += 1
    end


    def puts(string='')
      spaces = @indent * 4
      @output.puts((' ' * spaces) + string)
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

          if new_last_line.length <= width
            m[0...-1] + [new_last_line]
          else
            m + [v]
          end
        }.join("\n")

      }.join("\n\n")
    end


  end
end
