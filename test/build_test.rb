require 'helpers'

describe 'Climate::Command.build' do
  describe 'with a single command' do

    let(:test_class) do
      Climate::Command('test') do
        arg :foo, "foo"
        opt :bar, "bar", :type => :string
      end
    end

    it "returns a constructed command instance" do
      test_instance, *others = test_class.build(["--bar", "baz", "foo"])
      assert test_instance
      assert others.empty?
      assert test_instance.class < Climate::Command
      assert_equal "baz", test_instance.options[:bar]
      assert_equal "foo", test_instance.arguments[:foo]
    end
  end

  describe 'with a command tree' do

    class TestClass < Climate::Command('test')
    end

    class ChildA < Climate::Command('child_a')
        subcommand_of TestClass
    end

    class ChildB < Climate::Command('child_b')
        subcommand_of TestClass
    end

    class ChildC < Climate::Command('child_c')
        subcommand_of TestClass
    end

    class ChildCA < Climate::Command('child_c_a')
        subcommand_of ChildC
    end

    class ChildCG < Climate::Command('child_c_b')
        subcommand_of ChildC
    end

    it "returns the parent command, plus the children it matched" do
      assert_equal [TestClass, ChildA], TestClass.build(["child_a"]).map(&:class)
      assert_equal [TestClass, ChildB], TestClass.build(["child_b"]).map(&:class)
      assert_equal [TestClass, ChildC, ChildCA], TestClass.build(["child_c", "child_c_a"]).map(&:class)
    end

    it "raises an error if it can't find a matching child command" do
      assert_raises Climate::UnknownCommandError do
        TestClass.build(["child_d"])
      end

      assert_raises Climate::UnknownCommandError do
        TestClass.build(["child_c", "child_x"])
      end
    end

    it "raises an error if it expected a child command arg to follow" do
      assert_raises Climate::MissingSubcommandError do
        TestClass.build([])
      end
      assert_raises Climate::MissingSubcommandError do
        TestClass.build(["child_c"])
      end
    end
  end
end
