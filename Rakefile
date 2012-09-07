require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :init do
  mkdir 'build' unless File.exists?('build')
end

task :clean do
  rm_r 'build'
end

task :install, :install_dir do |t, args|
  dir = args[:install_dir]
  dest_dir = File.join(dir, 'usr/lib/ruby/1.8')
  cp_r('lib/.', dest_dir)
  cp('debian/trollop-2.0.rb', File.join(dest_dir, 'trollop.rb'))
end
