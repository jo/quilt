# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{couch-quilt}
  s.version = "0.2.1"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Johannes Jörg Schmidt, TF"]
  s.date = %q{2010-01-31}
  s.default_executable = %q{couchquilt}
  s.description = %q{Access CouchDB JSON documents from filesystem.}
  s.email = %q{schmidt@netzmerk.com}
  s.executables = ["couchquilt"]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "README.md",
    "INSTALL",
     "Rakefile",
     "bin/couchquilt",
     "lib/couchquilt.rb",
      "lib/couchquilt/couch_client.rb",
      "lib/couchquilt/debugged_fs.rb",
      "lib/couchquilt/fs.rb",
     "spec/spec_helper.rb",
     "spec/couchquilt_spec.rb",
  ]
  s.homepage = %q{http://jo.github.com/quilt/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{couch-quilt}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Read and write CouchDB documents via FUSE userspace filesystem.}
  s.test_files = [
    "spec/spec_helper.rb",
    "spec/couchquilt_spec.rb",
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.3"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.3"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.3"])
  end
end

