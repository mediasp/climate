require 'rubygems'
require 'climate'
require 'minitest/spec'
require 'minitest/autorun'
require 'popen4'
require 'fileutils'
require 'tempfile'

module PopenHelper
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

end
