# Quilt mixes CouchDB Design Documents into FUSE

require 'fusefs'
require 'lib/quilt_db'
require 'open-uri'

class Quilt < FuseFS::FuseDir
  attr_reader :server_name, :db

  # initializes Quilt with the database server name
  def initialize(server_name = "http://127.0.0.1:5984")
    @server_name = server_name
    @db = QuiltDB.new(server_name)
  end

  # list contents of path
  def contents(path)
    database, id, *rest = extract_parts(path)

    if database.nil?
      # we are on quilts docroot
      db.databases
    elsif id.nil?
      # we are at the root of a database
      ["_design"] + db.documents(database)
    elsif id == "_design" && rest.empty?
      # we requested a list of all design documents of a database
      db.design_documents(database)
    elsif id =~ /_design\// && rest == ["_show"]
      doc = get_document_contents(database, id, ["shows"])
      doc.keys.sort
    elsif id =~ /_design\// && rest == ["_list"]
      # list all list functions
      doc = get_document_contents(database, id, ["lists"])
      doc.keys.sort
    elsif id =~ /_design\// && rest.size == 2 && rest.first == "_list"
      # list all view functions
      doc = get_document_contents(database, id, ["views"])
      doc.keys.sort.map { |name| append_extname(name, "") }
    elsif id =~ /_design\// && rest.size == 2 && rest.first == "_show"
      # list all documents
      db.documents(database).map { |name| append_extname(name, "") }
    else
      # get the document
      doc = get_document_contents(database, id, rest)

      arr = if doc.is_a?(Hash)
              # Hash is mapped into directory
              doc.keys.sort.map { |k| append_extname(k, doc[k]) }
            elsif doc.is_a?(Array)
              # Array is mapped into directory
              doc.map { |k| append_extname(doc.index(k), k) }
            else
              []
            end

      if id =~ /_design\// && rest.empty?
        # we are inside a design document root
        (arr + ["_list", "_show"]).sort
      else
        # we are inside a document and list the json mapping content
        arr
      end
    end

  rescue => e
    puts e.message, e.backtrace
  end

  # is path a directory?
  def directory?(path)
    database, id, *parts = extract_parts(path)
    # /
    return true if database.nil?
    # /database 
    return db.database?(database) if id.nil?
    # /database/_design
    return true if id == "_design" && parts.empty?
    # show and list functions are mapped to directories,
    # as well as their names
    return true if id =~ /\A_design/ && parts.size <= 2 && ["_list", "_show"].include?(parts.first)
    # look into document
    res = get_document_contents(database, id, parts)
    # arrays and hashes are mapped into directories
    res.is_a?(Hash) || res.is_a?(Array)
  rescue => e
    puts e.message, e.backtrace
  end

  # is path a file?
  # # every javascript file is a JSON value.
  def file?(path)
    File.extname(path) == ".js"
  end

  # reading file contents of path
  def read_file(path)
    return unless file?(path)
    database, id, *parts = extract_parts(path)
    if parts.first == "_show"
      # eg http://127.0.0.1:5984/quilt-test-db/_design/document/_show/document
      parts.shift
      filename = File.join(@server_name, database, id, "_show", parts)
      file = open(remove_extname(filename))
      file.read if file
    elsif parts.first == "_list"
      # eg http://127.0.0.1:5984/quilt-test-db/_design/document/_list/by_name
      parts.shift
      filename = File.join(@server_name, database, id, "_list", parts)
      file = open(remove_extname(filename))
      file.read if file
    else
      # read the document (part) at path
      get_document_contents(database, id, parts).to_s
    end
  rescue => e
    puts e.message, e.backtrace
  end

  # calculate file size
  def size(path)
    return 4096 unless file?(path)
    str = read_file(path)
    return 0 unless str
    str.length
  end

  # is path writable?
  def can_write?(path)
    return if File.basename(path) =~ /^_/
    # every file is writable
    file?(path)
  end

  # writes content str to path
  def write_to(path, str)
    database, id, *parts = extract_parts(path)
    # fetch document
    doc = db.get_document(database, id)
    # update the value that the file at path holds
    update_value(doc, parts, str)
    # save document
    db.save_document(database, doc)
  rescue => e
    puts e.message, e.backtrace
  end

  # can I delete path?
  # This helps editors, but we don't really use it.
  def can_delete?(path)
    true
  end

  private

  # get document id from database,
  # or a part of the document.
  def get_document_contents(database, id, parts = [])
    doc = db.get_document(database, id)
    parts.each do |part|
      doc = doc ? doc[remove_extname(part)] : nil
    end
    doc
  end

  # list the documents contents as mapped into directory at path
  def list_document_content(path)
    database, id, *parts = extract_parts(path)
    # get the document
    doc = get_document_contents(database, id, parts)
    if doc.is_a?(Hash)
      # Hash is mapped into directory
      doc.keys.sort.map { |k| append_extname(k, doc[k]) }
    elsif doc.is_a?(Array)
      # Array is mapped into directory
      doc.map { |k| append_extname(doc.index(k), k) }
    else
      []
    end
  end

  # updates a part of a hash
  # Example:
  #  update_value({:a => { :b => 'c'}}, [:a, :b], 'cis') #=> {:a => { :b => 'cis'}}
  def update_value(hash, keys, value)
    key = remove_extname(keys.shift)
    if keys.empty?
      hash[key] = value
    else
      hash[key] = update_value(hash[key], keys, value)
    end
    hash
  end

  # remove extname to get the id
  def remove_extname(filename)
    filename.sub(/(\.(f|i))?\.js\z/, "")
  end

  # Appends extname, that is: builds a filename from key and value.
  # Note: values are casted by extension.
  def append_extname(key, value)
    basename = key.is_a?(Integer) ? "%.3d" % key : key

    if value.is_a?(Float)
      "#{basename}.f.js"
    elsif value.is_a?(Integer)
      "#{basename}.i.js"
    elsif value.is_a?(String)
      "#{basename}.js"
    else
      basename
    end
  end

  # gets the database, id and parts from path
  def extract_parts(path)
    database, id, *parts = scan_path(path)
    if id == "_design" && !parts.empty?
      id << "/#{parts.shift}"
    end
    [database, id] + parts
  end
end
