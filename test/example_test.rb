require 'test/helpers'
require 'popen4'
require 'fileutils'
require 'tempfile'

describe 'example.rb' do

  def run_cmd(cmd)
    @last_command = cmd

    @last_status = POpen4.popen4(@last_command) do |stdout, stderr, stdin, pid|
      @last_stdout = stdout.read.strip
      @last_stderr = stderr.read.strip
      @last_pid = pid
    end
  end

  def last_run
    {
      :command => @last_command,
      :stdout  => @last_stdout,
      :stderr  => @last_stderr,
      :pid     => @last_pid,
      :status  => @last_status
    }
  end

  def exec(cmd)
    run_cmd cmd
    if @last_status.exitstatus != 0
      raise "command: #{cmd} failed with #{@last_status.exitstatus}\n#{@all_output}"
    end
    true
  end

  def all_output
    @last_stdout + "\n" + @last_stderr
  end

  attr_reader :last_stdout, :last_stderr, :last_status


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
    assert_match 'Unknown command: peter', last_stderr
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

    it 'with no arguments it dumps everything on to stdout' do
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
