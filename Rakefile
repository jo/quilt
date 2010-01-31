require 'rake'
require 'spec/rake/spectask'

task :default => :spec

desc "Run all examples"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/*_spec.rb']
  t.spec_opts = ["--color"]
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new(:coverage) do |t|
  t.spec_files = FileList['spec/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', '/var/lib/gems', '--exclude', "spec"]
end

desc "Display Quilt version"
task :version do
  require "lib/quilt"
  puts Quilt::VERSION
end
