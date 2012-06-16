# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'climate/version'

spec = Gem::Specification.new do |s|
  s.name   = "climate"
  s.version = Climate::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Nick Griffiths']
  s.email = ["nicobrevin@gmail.com"]
  s.summary = "Library for building command line interfaces"
  s.description = 'Library, not a framework, for building command line interfaces to your ruby application'

  s.add_dependency('trollop')
  s.add_development_dependency('minitest')

  s.files = Dir.glob("lib/**/*.rb") + ['README']
end
