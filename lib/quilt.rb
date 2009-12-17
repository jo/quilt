# Quilt mixes CouchDB Design Documents into FUSE

require 'fusefs'
require 'lib/quilt_db'

class Quilt < FuseFS::FuseDir
  attr_reader :db

  # initializes Quilt with the database server name
  def initialize(db_server = "http://127.0.0.1:5984")
    @db = QuiltDB.new(db_server)
  end

  # list contents of path
  # TODO:
  # /database/_design/document/show
  # /database/_design/document/list
  def contents(path)
    database, id, *rest = scan_path(path)
    if database.nil?
      # we are on quilts docroot
      db.databases
    elsif id.nil?
      # we are at the root of a database
      db.documents(database)
    elsif id == "_design" && rest.empty?
      # we requested a list of all design documents of a database
      db.design_documents(database)
    else
      # we are inside a document and list the json mapping content
      list_document_content(path)
    end
  end

  # is path a directory?
  def directory?(path)
    database, id, *parts = scan_path(path)
    # root is a directory
    return true if database.nil?
    # databases are mapped to directories
    return db.database?(database) if id.nil?
    if id == "_design"
      # _design is a directory
      return true if parts.empty?
      # look inside the design document
      id = [id, parts.shift].join("/")
    end
    # look into document
    res = get_document_contents(database, id, parts)
    # arrays and hashes are mapped into directories
    res.is_a?(Hash) || res.is_a?(Array)
  end

  # is path a file?
  # # every javascript file is a JSON value.
  def file?(path)
    File.extname(path) == ".js"
  end

  # reading file contents of path
  def read_file(path)
    return unless file?(path)
    database, id, *parts = id_and_parts_from(path)
    # read the document (part) at path
    get_document_contents(database, id, parts).to_s
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
    # every file is writable
    file?(path)
  end

  # writes content str to path
  def write_to(path, str)
    database, id, *parts = id_and_parts_from(path)
    # fetch document
    doc = db.get_document(database, id)
    # update the value that the file at path holds
    update_value(doc, parts, str)
    # save document
    db.save_document(database, doc)
  end

  # can I delete path?
  # This helps editors, but we don't really use it.
  def can_delete?(path)
    true
  end

  private

  # updates a part of a json document.
  # Note that files are just parts of documents.
  # Example:
  #  update_value({:a => { :b => 'c'}}, [:a, :b], 'cis') #=> {:a => { :b => 'cis'}}
  def update_value(hash, keys, value)
    key = id_for(keys.shift)
    if keys.empty?
      hash[key] = value
    else
      hash[key] = update_value(hash[key], keys, value)
    end
    hash
  end

  # get document id from database,
  # or a part of the document.
  def get_document_contents(database, id, parts = [])
    doc = db.get_document(database, id)
    parts.each do |part|
      doc = doc[id_for(part)]
    end
    doc
  end

  # list the documents contents as mapped into directory at path
  def list_document_content(path)
    database, id, *parts = id_and_parts_from(path)
    # get the document
    doc = get_document_contents(database, id, parts)
    if doc.is_a?(Hash)
      # Hash is mapped into directory
      doc.keys.sort.map { |k| filename_for(k, doc[k]) }
    elsif doc.is_a?(Array)
      # Array is mapped into directory
      doc.map { |k| filename_for(doc.index(k), k) }
    else
      []
    end
  end

  # build the id from filename
  def id_for(filename)
    filename.sub(/(\.(f|i))?\.js\z/, "")
  end

  # Builds a filename from key and value.
  # Note: values are casted by extension.
  def filename_for(key, value)
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
  def id_and_parts_from(path)
    database, name, *parts = scan_path(path)
    if name == "_design"
      name << "/#{parts.shift}"
    end
    [database] + [name] + parts
  end
end
