require 'test/helpers'

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
        add_subcommand("pete", ExampleCommandFoo)
      end
    end

    assert_raises Climate::DefinitionError do
      Class.new(Climate::Command) do
        add_subcommand("pete", ExampleCommandFoo)
        arg "foo", "bar"
      end
    end
  end

  it 'lets the child command add itself to a parent' do
    child = Class.new(Climate::Command) do
      subcommand 'child', ParentCommandFoo

      def run ; STASH[:ran] = true ;  end
    end

    ParentCommandFoo.run ['child']
    assert STASH[:ran]
  end

  describe '.run' do

    class ParentCommandFoo < Climate::Command
      opt 'log', 'whether to log', :default => false
    end

    class ExampleCommandFoo < Climate::Command

      subcommand 'example', ParentCommandFoo
      opt 'num_tanks', 'how many tanks', :default => 1
      arg 'path', 'path to file'

      def run
        STASH[:parent] = parent
        STASH[:arguments] = arguments
        STASH[:options] = options
      end
    end

    describe 'with a basic command' do
      it 'will instantiate an instance of the command and run it using the ' +
        'provided arguments' do

        ExampleCommandFoo.run(["--num-tanks=4", "/tmp/sexy"])

        assert_equal '/tmp/sexy', STASH[:arguments]['path']
        assert_equal 4, STASH[:options]['num_tanks']
      end
    end

    describe 'with a parent command' do
      it 'will record its arguments before passing control to the child' do
        ParentCommandFoo.run(["--log", "example", "--num-tanks=5", "/tmp/hoe"])

        assert STASH[:parent]
        assert STASH[:parent].options['log']
        assert_equal ParentCommandFoo, STASH[:parent].class
      end
    end
  end
end
