require 'test/helpers'

describe Climate::Command do

  class ExampleCommandFoo < Climate::Command
    opt 'num_tanks', 'how many tanks', :default => 1
    arg 'path', 'path to file'

    def self.saved_hash
      @saved_hash ||= {}
    end

    def run
      self.class.saved_hash[:arguments] = arguments
      self.class.saved_hash[:options] = options
    end
  end

  class ParentCommandFoo < Climate::Command
    opt 'log', 'whether to log', :default => false
    add_subcommand "example", ExampleCommandFoo
  end


  def saved_hash
    ExampleCommandFoo.saved_hash
  end

  before do
    ExampleCommandFoo.saved_hash.clear
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

  describe '.run' do
    describe 'with a basic command' do
      it 'will instantiate an instance of the command and run it using the ' +
        'provided arguments' do

        ExampleCommandFoo.run(["--num-tanks=4", "/tmp/sexy"])

        assert_equal '/tmp/sexy', saved_hash[:arguments]['path']
        assert_equal 4, saved_hash[:options]['num_tanks']
      end
    end

    describe 'with a parent command' do

      it 'will record its arguments before passing control to the child' do
        ParentCommandFoo.run(["--log", "example", "--num-tanks=5", "/tmp/hoe"])
      end

    end
  end
end
