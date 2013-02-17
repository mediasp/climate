require 'helpers'

describe 'example.rb' do
  include PopenHelper
  def run_example(args, opts={})
    defaults = opts[:without_defaults] ? '' : "--config-file=#@conf_filename "
    run_cmd('ruby -rrubygems -Ilib example.rb ' + defaults + args)
  end

  before do
    @conf_filename = "/tmp/does_not_exist_#{Time.now.to_i}"
  end

  after do
    FileUtils.rm(@conf_filename) if File.exists?(@conf_filename)
  end

  it 'shows global help if you run it with -h' do
    run_example '-h'
    assert_match "usage: example", last_stdout
    assert_equal 0, last_status.exitstatus
    assert_equal '', last_stderr
  end

  it 'gives an error and shows global help if you run it with no arguments' do
    run_example ''
    assert_match 'usage: example', last_stdout
    assert_equal 1, last_status.exitstatus
    assert_match 'Missing argument', last_stderr
  end

  it 'gives an error and shows global help if you run it with an unknown command' do
    run_example 'peter'
    assert_match 'usage: example', last_stdout
    assert_equal 1, last_status.exitstatus
    assert_match "Unknown command 'peter': example expects one of: ", last_stderr
  end

  it 'gives an error if you supply an option it does not recognise' do
    run_example '--leggings'
    assert_match 'usage: example', last_stdout
    assert_equal 1, last_status.exitstatus
    assert_match 'Unknown argument: --leggings', last_stderr
  end

  describe 'set' do

    it 'gives help if -h is supplied' do
      run_example 'set -h'
      assert_match 'usage: example set', last_stdout
      assert_equal 0, last_status.exitstatus
    end

    it 'gives an error if you do not supply all the required arguments' do
      run_example 'set'
      assert_match 'Missing argument: key', last_stderr
      assert_equal 1, last_status.exitstatus
      assert_match 'usage: example set <key> [<value>]', last_stdout
    end

    it 'gives an error if you do not supply a required option' do
      run_example "set test_key test_value", :without_defaults => true
      assert_match "Missing argument: --config-file", last_stderr
      assert_equal 1, last_status.exitstatus
    end

    it 'exits with 1 if the command raises an ExitException, printing out ' +
      'the error message on to stdout' do

      run_example "set test_key test_value"
      assert_match "No config file: #@conf_filename", last_stderr
      assert_equal 1, last_status.exitstatus
    end

    it 'exits with 0 if the command returns normally' do
      run_example "-c set test_key test_value"
      assert_equal "", last_stderr
      assert_equal "", last_stdout
      assert_equal 0, last_status.exitstatus
    end
  end

  describe 'show' do

    before do
      run_example "-c set fave_food lentils"
      run_example "set fave_animal llama"
      run_example "set fave_book 'wuthering heights'"
    end

    it 'with no arguments it dumps everything on to stdout in text format' do
      run_example "show"
      assert_equal 0, last_status.exitstatus
      assert_match "fave_animal: llama", last_stdout
      assert_match "fave_food: lentils", last_stdout
      assert_match "fave_book: wuthering heights", last_stdout
    end

    it 'can take a single argument which shows a single value' do
      run_example "show fave_book"
      assert_equal 0, last_status.exitstatus
      assert_match "fave_book: wuthering heights", last_stdout
    end

    it 'can take multiple arguments which shows a value for each argument' do
      run_example "show fave_book fave_animal"
      assert_equal 0, last_status.exitstatus
      assert_match "fave_book: wuthering heights\nfave_animal: llama", last_stdout
    end

    it 'can take multiple --value options to override config values' do
      run_example "--value=fave_book=boy --value=fave_meal=toast show"
      assert_equal 0, last_status.exitstatus, last_stderr
      assert_match "fave_book: boy", last_stdout
      assert_match "fave_meal: toast", last_stdout
    end

    it 'can take a --json option and print it out in json format' do
      run_example "show fave_book --json"
      assert_equal 0, last_status.exitstatus
      assert_match "{\n  \"fave_book\" : \"wuthering heights\"\n}", last_stdout
    end

    it 'barfs if you supply json and text options' do
      run_example "show fave_book --json --text"
      assert_equal 1, last_status.exitstatus
      assert_match "Conflicting options given: --json conflicts with --text", last_stderr
    end
  end

  describe 'test' do
    it 'lets you exit with a non-zero exit code without printing anything on ' +
      'to stdout and stderr' do
      run_example '-c set foo bar2'
      assert_equal 0, last_status.exitstatus
      run_example 'test foo bar1'
      assert_equal '', last_stderr
      assert_equal '', last_stdout
      assert_equal 2, last_status.exitstatus
    end
  end

  describe 'echo - disable_parsing example' do
    it 'outputs any arguments you give it, but does not parse them' do
      run_example "echo this --shizzle -blows my mind"
      assert_equal 0, last_status.exitstatus, last_stderr
      assert_match '["this", "--shizzle", "-blows", "my", "mind"]', last_stdout
    end
  end

  describe 'man page output' do

    # Could do some assertions on the output, but that is a lot of effort -
    # let's just check it exits properly

    it 'can create a man page for the parent command' do
      run_cmd "ruby -rrubygems -Ilib -rexample bin/climate-man Example::Parent"
      assert_equal 0, last_status.exitstatus, last_stderr
    end

    it 'can create a man page for the child commands' do
      run_cmd "ruby -rrubygems -Ilib -rexample bin/climate-man Example::Show"
      assert_equal 0, last_status.exitstatus, last_stderr

      run_cmd "ruby -rrubygems -Ilib -rexample bin/climate-man Example::Set"
      assert_equal 0, last_status.exitstatus, last_stderr
    end

    it 'can be given a path to a different template to use' do
      template = Tempfile.new('template')
      begin
        template.write <<EOF
This template is silly
EOF
        template.flush

        run_cmd "ruby -rrubygems -Ilib -rexample bin/climate-man" +
          " --template=#{template.path} Example::Set"
        assert_equal 0, last_status.exitstatus
        assert_match 'This template is silly', last_stdout

      ensure
        template.close
      end
    end
  end

end
