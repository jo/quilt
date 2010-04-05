# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{couch-quilt}
  s.version = "0.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Johannes J\303\266rg Schmidt"]
  s.date = %q{2010-04-05}
  s.default_executable = %q{couchquilt}
  s.description = %q{Access CouchDB JSON documents from filesystem.}
  s.email = %q{schmidt@netzmerk.com}
  s.executables = ["couchquilt"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "CHANGELOG.rdoc",
     "README.rdoc",
     "Rakefile",
     "bin/couchquilt",
     "couch-quilt.gemspec",
     "lib/couchquilt.rb",
     "lib/couchquilt/core_ext/array.rb",
     "lib/couchquilt/core_ext/hash.rb",
     "lib/couchquilt/couch_client.rb",
     "lib/couchquilt/database.rb",
     "lib/couchquilt/debugged_fs.rb",
     "lib/couchquilt/fs.rb",
     "lib/couchquilt/mapper.rb",
     "lib/couchquilt/version.rb",
     "spec/couchquilt/core_ext_spec.rb",
     "spec/couchquilt/fs_spec.rb",
     "spec/couchquilt/mapper_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://jo.github.com/quilt}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{couch-quilt}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Access CouchDB from filesystem.}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/couchquilt/fs_spec.rb",
     "spec/couchquilt/core_ext_spec.rb",
     "spec/couchquilt/mapper_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.4.1"])
      s.add_runtime_dependency(%q<json_pure>, [">= 1.2.2"])
      s.add_runtime_dependency(%q<fusefs>, [">= 0.7.0"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.4.1"])
      s.add_dependency(%q<json_pure>, [">= 1.2.2"])
      s.add_dependency(%q<fusefs>, [">= 0.7.0"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.4.1"])
    s.add_dependency(%q<json_pure>, [">= 1.2.2"])
    s.add_dependency(%q<fusefs>, [">= 0.7.0"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

