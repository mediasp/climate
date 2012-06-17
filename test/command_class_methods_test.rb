require 'test/helpers'

describe Climate::Command::ClassMethods do

  before do
    @subject = Object.new.extend(Climate::Command::ClassMethods)
  end

  after do
    @subject = nil
  end

  describe "#cli_argument" do
    it "lets you declare a cli argument" do
      @subject.cli_argument "cat_count", "number of cats"
      arg = @subject.send(:cli_arguments).find {|h| h.name == "cat_count" }
      assert arg
      assert_equal "number of cats", arg.description
      assert_equal true, arg.required?
      assert_equal "CAT_COUNT", arg.formatted
    end

    it "lets you declare multiple cli arguments, remembering the order in which they " +
      "are declared" do

      @subject.cli_argument "foo", "level of foo"
      @subject.cli_argument "bar", "level of bar"

      assert_equal ["foo", "bar"], @subject.send(:cli_arguments).map {|a| a.name }
    end

    it "lets you declare an optional argument" do
      @subject.cli_argument "log", "whether to log", :required => false
      arg = @subject.send(:cli_arguments).find {|h| h.name == "log" }
      assert arg
      assert_equal false, arg.required?
      assert_equal "[LOG]", arg.formatted
    end

    it "raises an error if you try to declare a required argument after an " +
      "optional one" do


      @subject.cli_argument "foo", "level of foo", :required => false

      assert_raises ArgumentDefinitionError do
        @subject.cli_argument "bar", "level of bar"
      end
    end
  end

  describe "#cli_option" do
    it "lets you declare an option with a name and a description" do
      @subject.cli_option "foo", "whether to foo"
      opt = @subject.send(:cli_options).find {|o| o.name == "foo" }
      assert opt
      assert "foo", opt.name
      assert "whether to foo", opt.description
    end
  end
end
