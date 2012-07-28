require 'test/helpers'
require 'stringio'

describe Climate::Parser do

  before do
    @subject = Climate::Parser.new
  end

  after do
    @subject = nil
  end

  describe "#parse" do

    describe "with a required argument" do

      before do
        @subject.arg "foo", "level of foo"
      end

      it "raises an error if you do not supply any arguments" do
        assert_raises Climate::MissingArgumentError do
          @subject.parse []
        end
      end

      it "raises an error if you supply too many arguments" do
        assert_raises Climate::UnexpectedArgumentError do
          @subject.parse ["grave", "digger"]
        end
      end

      it "returns an arguments hash with the parsed argument" do
        args, opts = @subject.parse ["sexyfeelings"]
        assert args
        assert_equal "sexyfeelings", args["foo"]
      end
    end

    describe "with a required and an optional argument" do

      before do
        @subject.arg "foo", "level of foo"
        @subject.arg "bar", "select your bar", :required => false
      end

      it "raises an error if you do not supply any arguments" do
        assert_raises Climate::MissingArgumentError do
          @subject.parse []
        end
      end

      it "returns the value of the required argument and null for the " +
        "optional one if you do not supply a second argument" do
        args, opts = @subject.parse ["maximum-foo"]
        assert args
        assert_equal "maximum-foo", args["foo"]
        assert_equal nil, args["bar"]
      end

      it "returns values for both arguments if both are supplied" do
        args, opts = @subject.parse ["maximum-foo", "redbar"]
        assert args
        assert_equal "maximum-foo", args["foo"]
        assert_equal "redbar", args["bar"]
      end

      it "raises an error if you supply too many arguments" do
        assert_raises Climate::UnexpectedArgumentError do
          @subject.parse ["totalfoo", "megabar", "wtf"]
        end
      end
    end

    describe "with an option with a default" do

      before do
        @subject.opt "foo", "foo time", :default => 'cats'
      end

      it "returns the default value if no foo option is supplied" do
        args, opts = @subject.parse []
        assert opts
        assert_equal "cats", opts["foo"]
      end

      it "returns the given value in the long form" do
        args, opts = @subject.parse ["--foo=totally-awesome"]
        assert opts
        assert_equal "totally-awesome", opts["foo"]
      end

      it "returns the given value in the short form" do
        args, opts = @subject.parse ["-f", "totally-awesome"]
        assert opts
        assert_equal "totally-awesome", opts["foo"]
      end

    end

    describe "with an option with a non-standard short form " do

      before do
        @subject.opt "foo", "foo time", :short => 'l', :type => String
      end

      it "returns the given value" do
        args, opts = @subject.parse ["-l", "bar"]
        assert opts
        assert_equal "bar", opts["foo"]
      end
    end

    describe "with an option with a non-standard long form " do

      before do
        @subject.opt "foo", "foo time", :long => 'whatevs', :type => String
      end

      it "returns the given value" do
        args, opts = @subject.parse ["--whatevs=bar"]
        assert opts
        assert_equal "bar", opts["foo"]
      end
    end

    describe "with a multi argument" do
      before do
        @subject.arg "foos", "all the foos you dream of", :multi => true
      end

      it "raises an error if you do not supply at least one foo" do
        assert_raises Climate::MissingArgumentError do
          @subject.parse []
        end
      end

      it "returns a single argument as a single element array" do
        args, _ = @subject.parse ["cat's"]
        assert_equal ["cat's"], args['foos']
      end

      it "returns multiple arguments as an array" do
        args, _ = @subject.parse ["cat's", "whiskers"]
        assert_equal ["cat's", "whiskers"], args['foos']
      end
    end

    describe "with a multi argument that is not required" do

      before do
        @subject.arg 'foos', 'so much foo in this club', :multi => true, :required => false
      end

      it "returns no arguments as an empty array" do
        args, _ = @subject.parse []
        assert_equal [], args['foos']
      end

      it "returns a single argument as a single element array" do
        args, _ = @subject.parse ["cat's"]
        assert_equal ["cat's"], args['foos']
      end

      it "returns multiple arguments as an array" do
        args, _ = @subject.parse ["cat's", "whiskers"]
        assert_equal ["cat's", "whiskers"], args['foos']
      end
    end

    describe "with some single arguments followed by a multi" do
      before do
        @subject.arg 'foo', 'foo'
        @subject.arg 'bar', 'bar', :required => false
        @subject.arg 'baz', 'many baz make light work', :multi => true, :required => false
      end

      it "can parse the single required argument" do
        args, _ = @subject.parse ['foo']
        assert_equal 'foo', args['foo']
      end

      it "can parse the required and an optional argument" do
        args, _ = @subject.parse ['foo', 'bar']
        assert_equal 'foo', args['foo']
        assert_equal 'bar', args['bar']
      end

      it "can parse the first two single args, followed by any number of multis" do
        args, _ = @subject.parse ['foo', 'bar', 'baz1', 'baz2', 'baz3']
        assert_equal 'foo', args['foo']
        assert_equal 'bar', args['bar']
        assert_equal ['baz1', 'baz2', 'baz3'], args['baz']
      end
    end

    describe "big juicy fruit example" do
      before do
        @subject.instance_eval do
          opt "log_stdout", "log stdout", :default => false
          opt "num_peaches", "peach count", :short => 'p', :default => 0

          opt "num_splines", "how many splines", :type => Integer,
          :required => true

          arg "path", "path to file"
          arg "output_host", "optional hose", :required => false
        end
      end

      it "raises an error if you do not supply any arguments" do
        assert_raises Climate::MissingArgumentError do
          @subject.parse ["--num-splines=1"]
        end
      end

      it "raises an error if you do not supply the required options" do
        assert_raises Climate::MissingArgumentError do
          @subject.parse ["/tmp"]
        end
      end

      it "returns provided values" do
        args, opts = @subject.parse ["/tmp", 'firehose', '--log-stdout',
          '-p', '5', '-n', '1']

        assert_equal '/tmp', args['path']
        assert_equal 'firehose', args['output_host']
        assert_equal true, opts['log_stdout']
        assert_equal 5, opts['num_peaches']
        assert_equal 1, opts['num_splines']
      end
    end
  end

  describe "#cli_argument" do
    it "lets you declare a cli argument" do
      @subject.arg "cat_count", "number of cats"
      arg = @subject.send(:cli_arguments).find {|h| h.name == "cat_count" }
      assert arg
      assert_equal "number of cats", arg.description
      assert_equal true, arg.required?
      assert_equal "<cat_count>", arg.usage
    end

    it "lets you declare multiple cli arguments, remembering the order in which they " +
      "are declared" do

      @subject.arg "foo", "level of foo"
      @subject.arg "bar", "level of bar"

      assert_equal ["foo", "bar"], @subject.send(:cli_arguments).map {|a| a.name }
    end

    it "lets you declare an optional argument" do
      @subject.arg "log", "whether to log", :required => false
      arg = @subject.send(:cli_arguments).find {|h| h.name == "log" }
      assert arg
      assert_equal false, arg.required?
      assert_equal "[<log>]", arg.usage
    end

    it "raises an error if you try to declare a required argument after an " +
      "optional one" do

      @subject.arg "foo", "level of foo", :required => false

      assert_raises Climate::DefinitionError do
        @subject.arg "bar", "level of bar"
      end
    end

    it "raises an error if you try to declare an argument after a multi" do
      @subject.arg "foos", "count your foos", :multi => true

      assert_raises Climate::DefinitionError do
        @subject.arg "bar", "before they bar"
      end
    end
  end

  describe "#cli_option" do
    it "lets you declare an option with a name and a description" do
      @subject.opt "foo", "whether to foo"
      opt = @subject.send(:cli_options).find {|o| o.name == "foo" }
      assert opt
      assert "foo", opt.name
      assert "whether to foo", opt.description
    end
  end
end
