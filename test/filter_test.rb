require 'helpers'

module FilterTest
describe 'allow parent commands to participate in the execution chain' do

  describe 'parent with a run(chain) method' do

    class Parent < Climate::Command('parent')
      def run(command)
        begin
          ["foo"] + command.run
        rescue => e
          "error: #{e}"
        end
      end
    end

    class Child < Climate::Command('child')
      subcommand_of Parent
      def run
        ["bar"]
      end
    end

    class ErrorChild < Climate::Command('error_child')
      subcommand_of Parent
      def run
        raise "foo"
      end
    end

    it 'allows the parent to run the next command' do
      assert_equal ["foo", "bar"], Parent.run(["child"])
    end

    it 'allows the parent to swallow a child error' do
      assert_equal "error: foo", Parent.run(["error_child"])
    end
  end

  describe 'parent with a run method (before filter)' do

    class BeforeParent < Climate::Command('parent')

      attr_reader :foo

      def run
        @foo = 'bar'
      end
    end

    class BeforeChild < Climate::Command('child')
      subcommand_of BeforeParent
      def run
        ancestor(BeforeParent).foo
      end
    end

    it 'runs the parent run method first, then carries on with normal execution' do
      assert_equal 'bar', BeforeParent.run(['child'])
    end
  end

end
end
