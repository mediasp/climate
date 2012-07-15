#! /usr/bin/env climate

extend Climate::Script
description "Open a file"

opt :log, "Whether to log to stdout", :default => false
arg :path, "Path to input file", :required => true

def run
  file = File.open(arguments[:path], 'r')
  puts("loaded #{file}") if options[:log]
end
