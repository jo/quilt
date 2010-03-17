require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require File.join(File.dirname(__FILE__), 'lib', 'couchquilt', 'version')

desc 'Default: run specs.'
task :default => :spec

desc "Run all examples"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ["--color"]
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new(:coverage) do |t|
  t.spec_files = FileList['spec/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', '/var/lib/gems', '--exclude', "spec"]
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "couch-quilt"
    s.version = Couchquilt::VERSION
    s.summary = "Access CouchDB from filesystem."
    s.email = "schmidt@netzmerk.com"
    s.homepage = "http://jo.github.com/quilt"
    s.description = "Access CouchDB JSON documents from filesystem."
    s.authors = ['Johannes Jörg Schmidt']
    s.rubyforge_project = "couch-quilt"
    s.add_dependency "rest-client", ">= 1.4.1"
    s.add_dependency "json_pure", ">= 1.2.2"
    s.add_development_dependency "rspec", ">= 1.2.9"
    #s.files =  FileList["[A-Z]*(.rdoc)", "{bin,lib,spec}/**/*", "README.md", "INSTALL", "Rakefile"]
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end
