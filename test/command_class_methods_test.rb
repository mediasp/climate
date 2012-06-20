require 'test/helpers'
require 'stringio'

describe Climate::Command::ClassMethods do

  before do
    @subject = Object.new.extend(Climate::Command::ClassMethods)
  end

  after do
    @subject = nil
  end

  describe "#parse" do

    describe "with a required argument" do

      before do
        @subject.cli_argument "foo", "level of foo"
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
        @subject.cli_argument "foo", "level of foo"
        @subject.cli_argument "bar", "select your bar", :required => false
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
        @subject.cli_option "foo", "foo time", :default => 'cats'
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
        @subject.cli_option "foo", "foo time", :short => 'l', :type => String
      end

      it "returns the given value" do
        args, opts = @subject.parse ["-l", "bar"]
        assert opts
        assert_equal "bar", opts["foo"]
      end
    end

    describe "with an option with a non-standard long form " do

      before do
        @subject.cli_option "foo", "foo time", :long => 'whatevs', :type => String
      end

      it "returns the given value" do
        args, opts = @subject.parse ["--whatevs=bar"]
        assert opts
        assert_equal "bar", opts["foo"]
      end
    end

    describe "big juicy fruit example" do
      before do
        @subject.instance_eval do
          cli_option "log_stdout", "log stdout", :default => false
          cli_option "num_peaches", "peach count", :short => 'p', :default => 0

          cli_option "num_splines", "how many splines", :type => Integer,
          :required => true

          cli_argument "path", "path to file"
          cli_argument "output_host", "optional hose", :required => false
        end
      end

      it "raises an error if you do not supply any arguments" do
        assert_raises Climate::MissingArgumentError do
          @subject.parse ["--num-splines=1"]
        end
      end

      it "raises an error if you do not supply the required options" do
        assert_raises Trollop::CommandlineError do
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

  describe "#help_banner" do

    before do
      @subject.instance_eval do
        cli_option "log_stdout", "log to stdout", :default => false
        cli_option "num_peaches", "peach count", :short => 'p', :default => 0

        cli_option "num_splines", "how many splines", :type => Integer,
        :required => true

        cli_argument "path", "path to file"
        cli_argument "output_host", "optional hose", :required => false
      end
    end

    it "outputs some useful output :)" do
      stringio = StringIO.new
      @subject.help_banner(stringio)
      output = stringio.string

      assert_match /path.+path to file/, output
      assert_match /output_host.+optional hose/, output
      assert_match /--log-stdout.+log to stdout/, output
      assert_match /--num-peaches.+-p.+peach count/, output
      assert_match /--num-splines.+.+how many splines/, output
    end

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

      assert_raises Climate::DefinitionError do
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
