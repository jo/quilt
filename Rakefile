task :default => :diff

desc "Load environment"
task :environment do
  require 'rubygems'
  require 'couchrest'

  # Application database
  DB = CouchRest.database("http://127.0.0.1:5984/nashi-01-development")

  # Application directory
  APP_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'app'))
  Dir.mkdir(APP_DIR) unless File.directory?(APP_DIR)

  class Hash
    def diff(h2)
      self.dup.delete_if { |k, v| h2[k] == v }.merge(h2.dup.delete_if { |k, v| self.has_key?(k) })
    end
  end

  def read_fs
    apps = Dir.glob("#{APP_DIR}/*")
    apps.each do |app_dirname|
      # app/Site
      hash = {}
      name = File.basename(app_dirname)
      id = File.join("_design", name)
      hash["_id"] = id
      hash["language"] = "javascript"
      # app/Site/rev
      rev_filename = File.join(app_dirname, "rev")
      rev = File.read(rev_filename).strip
      hash["_rev"] = rev
      # app/Site/views
      hash["views"] = {}
      view_dirnames = Dir.glob("#{app_dirname}/views/*")
      view_dirnames.each do |view_dirname|
        # app/Site/views/by_name
        view_name = File.basename(view_dirname)
        hash["views"][view_name] = {}
        function_filenames = Dir.glob("#{view_dirname}/*.js")
        function_filenames.each do |function_filename|
          # app/Site/views/by_name/map.js
          fn_name = File.basename(function_filename).sub(/\.js\z/, '')
          hash["views"][view_name][fn_name] = File.read(function_filename)
        end
      end
      yield hash
    end
  end
end

desc "Diff filesystem database"
task :diff => :environment do
  read_fs do |hash|
    doc = DB.get hash["_id"]
    diff = hash.diff(doc)
    if diff != {}
      puts "Application `%s' differs:" % hash["_id"]
      puts "<<< Filesystem:"
      puts diff.inspect
      puts ">>> Database:"
      puts doc.diff(hash).inspect
      puts "-"*70
    end
  end
end

desc "Pull latest application code"
task :pull => :environment do
  docs = DB.documents :startkey => "_design/", :endkey => "_design/_", :include_docs => true
  raise "no design documents found" unless docs.is_a?(Hash)
  docs["rows"].each do |app|
    id = app["id"]
    doc = app["doc"]
    rev = doc["_rev"]
    name = id.sub(/\A_design\//, "")
    # app/Site
    dirname = File.join(APP_DIR, name)
    Dir.mkdir(dirname) unless File.directory?(dirname)
    # app/Site/rev
    rev_filename = File.join(dirname, "rev")
    File.open(rev_filename, "w") { |f| f << rev << "\n" }
    # app/Site/views
    views_dirname = File.join(dirname, "views")
    Dir.mkdir(views_dirname) unless File.directory?(views_dirname)
    doc["views"].each do |name, functions|
      # app/Site/views/by_name
      view_dirname = File.join(views_dirname, name)
      Dir.mkdir(view_dirname) unless File.directory?(view_dirname)
      functions.each do |name, value|
        # app/Site/views/by_name/map.js
        view_filename = File.join(view_dirname, "#{name}.js")
        File.open(view_filename, "w") { |f| f << value }
      end
    end
  end
end

desc "Push application code"
task :push => :environment do
  read_fs do |hash|
    doc = DB.get hash["_id"]
    diff = hash.diff(doc)
    name = hash["_id"].sub(/\A_design\//, "")
    if diff != {}
      puts "Pushing %s" % name
      res = DB.save_doc(hash)
      new_rev = res["rev"]
      puts "Document is at revision %s" % new_rev
      dirname = File.join(APP_DIR, name)
      rev_filename = File.join(dirname, "rev")
      File.open(rev_filename, "w") { |f| f << new_rev << "\n" }
    end
  end
end
