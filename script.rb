
extend Climate::Script
description "Open a file"

opt :log, "Whether to log to stdout", :default => false
arg :path, "Path to input file", :required => true

def run

  if File.directory?(arguments[:path])
    raise Climate::ExitException, 'path is a directory'
  end

  file = File.open(arguments[:path], 'r')
  puts("loaded #{arguments[:path]}") if options[:log]
end
