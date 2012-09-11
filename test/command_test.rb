require 'helpers'
require 'stringio'

describe Climate::Command do

  # place to put side effects
  STASH = {}

  before do
    STASH.clear
  end

  it "will not let you mix arguments with subcommands" do
    assert_raises Climate::DefinitionError do
      Class.new(Climate::Command) do
        arg "foo", "bar"
        add_subcommand(ExampleCommandFoo)
      end
    end

    assert_raises Climate::DefinitionError do
      Class.new(Climate::Command) do
        add_subcommand(ExampleCommandFoo)
        arg "foo", "bar"
      end
    end
  end

  it 'lets the child command add itself to a parent' do
    child = Class.new(Climate::Command) do
      name 'child'
      subcommand_of ParentCommandFoo

      def run ; STASH[:ran] = true ;  end
    end

    ParentCommandFoo.run ['child']
    assert STASH[:ran]
  end

  class ParentCommandFoo < Climate::Command
    name 'parent'
    description 'Parent command that does so many things, it is truly wonderful'
    opt 'log', 'whether to log', :default => false
  end

  class ExampleCommandFoo < Climate::Command
    name  'example'
    subcommand_of ParentCommandFoo
    description 'This command is an example to all other commands'
    opt 'num_tanks', 'how many tanks', :default => 1
    arg 'path', 'path to file'

    def run
      STASH[:parent] = parent
        STASH[:arguments] = arguments
      STASH[:options] = options
    end
  end

  describe '.help' do
    it 'Changes single newlines in to spaces and collapses space (climate#2)' do
      example_class = Class.new(Climate::Command) do
        name 'example'
        description <<EOF
this    should be
on one   line.

But this is a new   paragraph.
EOF
      end

      stringio = StringIO.new('')
      help = Climate::Help.new(example_class, :output => stringio)
      help.print_description

      assert_equal "\nDescription\n    this should be on one line.\n    \n    But this is a new paragraph.\n",
      stringio.string
    end
  end

  describe '.run' do

    describe 'accessing raw argv' do

      before do
        @subject = Class.new(Climate::Command) do
          name 'foo'

          arg :things, 'lots of things', :multi => true
          opt :count, 'counter', :type => :int

          def run
            self
          end
        end
      end

      it 'exposes the argument list unaltered past the command name' do
        cmd = @subject.run ['this', 'is', 'a thing', '-c', '6']
        assert_equal ['this', 'is', 'a thing', '-c', '6'], cmd.argv
      end

      it 'remembers the original and complete ARGV list' do
        # cant think of a way to test this without launching a new process
      end

      it 'lets you disable normal parsing by specifying `disable_parsing`' do
        @subject.disable_parsing
        cmd = @subject.run ['this', 'is', 'a thing', '-c', '6', '--unknown']
        assert_equal ['this', 'is', 'a thing', '-c', '6', '--unknown'], cmd.argv
        assert_nil cmd.arguments
        assert_nil cmd.options
      end
    end

    describe 'when the command does not define a run method (climate#1)' do
      it 'will raise a NotImplementedError' do
        example = Class.new(Climate::Command) do
          name 'example'
        end

        assert_raises NotImplementedError do
          example.run([])
        end
      end
    end

    describe 'with a basic command' do
      it 'will instantiate an instance of the command and run it using the ' +
        'provided arguments' do

        ExampleCommandFoo.run(["--num-tanks=4", "/tmp/sexy"])

        assert_equal '/tmp/sexy', STASH[:arguments]['path']
        assert_equal 4, STASH[:options]['num_tanks']
      end

      it 'will supply a missing command_class to any CommandError that ' +
        'is raised' do
        command_class = Class.new(Climate::Command) do
          name 'test'

          def run
            raise Climate::ExitException, 'too many oranges'
          end
        end

        begin
          command_class.run([])
          assert false, 'should have raised an exit exception'
        rescue Climate::ExitException => e
          assert_equal command_class, e.command_class
        end
      end
    end

    describe 'with a parent command' do
      it 'will record its arguments before passing control to the child' do
        ParentCommandFoo.run(["--log", "example", "--num-tanks=5", "/tmp/hoe"])

        assert STASH[:parent]
        assert STASH[:parent].options['log']
        assert_equal ParentCommandFoo, STASH[:parent].class
      end

      it 'will raise a missing argument exception if no argument is passed' do
        assert_raises Climate::MissingArgumentError do
          ParentCommandFoo.run(["--log"])
        end
      end

      it 'will supply a missing command_class to a CommandError that is raised' do
        command_class = Class.new(Climate::Command) do
          name 'test'
          subcommand_of ParentCommandFoo

          def run
            raise Climate::ExitException, 'too many oranges'
          end
        end

        begin
          ParentCommandFoo.run ['test']
        rescue Climate::ExitException => e
          assert_equal command_class, e.command_class
        end
      end
    end
    describe "testing that an argument with certain properties is expected" do
      before(:all) do
        @example = Class.new(Climate::Command) do
          name 'test'
          arg :required_argument, "A required argument"
          arg :optional_argument, "An optional argument", :required => false
          arg :multiple_argument, "An argument with multiple values", :multi => true, :required => false
        end
      end
      describe "has_argument?" do
        it 'returns true when the named argument is defined' do
          assert @example.has_argument?(:optional_argument)
        end
        it 'returns false when the named arguement is not defined' do
          refute @example.has_argument?(:nonexistent_argument)
        end
      end
      describe "has_required_argument?" do
        it 'returns true when the named argument is defined and required' do
          assert @example.has_required_argument?(:required_argument)
        end
        it 'returns false when the named argument is defined and not required' do
          refute @example.has_required_argument?(:optional_argument)
        end

        it 'returns false when the named argument is not defined' do
          refute @example.has_required_argument?(:nonexistent_argument)
        end
      end
      describe "has_multi_argument?" do
        it 'returns true when the named argument is defined and takes multiple values' do
          assert @example.has_multi_argument?(:multiple_argument)
        end
        it 'returns false when the named argument is defined and not multiple' do
          refute @example.has_multi_argument?(:optional_argument)
        end

        it 'returns false when the named argument is not defined' do
          refute @example.has_multi_argument?(:nonexistent_argument)
        end
      end
    end
  end
end
