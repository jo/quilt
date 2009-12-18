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
      # /
      db.databases
    elsif id.nil?
      # /database_id
      ["_design"] + db.documents(database)
    elsif id == "_design" && rest.empty?
      # /database_id/_design
      db.design_documents(database)
    elsif id =~ /_design\// && rest == ["_show"]
      # /database_id/_design/design_document_id/_show
      doc = get_document_part(database, id, ["shows"])
      doc.keys.sort
    elsif id =~ /_design\// && rest == ["_list"]
      # /database_id/_design/design_document_id/_list
      doc = get_document_part(database, id, ["lists"])
      doc.keys.sort
    elsif id =~ /_design\// && rest.size == 2 && rest.first == "_list"
      # /database_id/_design/design_document_id/_list/view_function_name
      doc = get_document_part(database, id, ["views"])
      doc.keys.sort.map { |name| "#{name}.html" }
    elsif id =~ /_design\// && rest.size == 2 && rest.first == "_show"
      # /database_id/_design/design_document_id/_list/show_function_name
      db.documents(database).map { |name| "#{name}.html" }
    else
      # /database_id/document_id
      # /database_id/document_id/object
      # /database_id/_design/design_document_id
      # /database_id/_design/design_document_id/object
      doc = get_document_part(database, id, rest)

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
        # /database_id/_design/design_document_id
        # add _list and _show directories
        (arr + ["_list", "_show"]).sort
      else
        # we are inside a document
        # list the json mapping content
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
    # /database_id
    return db.database?(database) if id.nil?
    # /database_id/_design
    return true if id == "_design" && parts.empty?
    # /database_id/_design/design_document_id/_list
    return true if id =~ /\A_design/ && parts == ["_list"]
    # /database_id/_design/design_document_id/_list/list_function_name
    return true if id =~ /\A_design/ && parts.size == 2 && parts.first == "_list"
    # /database_id/_design/design_document_id/_show
    return true if id =~ /\A_design/ && parts == ["_show"]
    # /database_id/_design/design_document_id/_show/show_function_name
    return true if id =~ /\A_design/ && parts.size == 2 && parts.first == "_show"
    # all other
    # look into document
    res = get_document_part(database, id, parts)
    # arrays and hashes are mapped into directories
    res.is_a?(Hash) || res.is_a?(Array)

  rescue => e
    puts e.message, e.backtrace
  end

  # is path a file?
  # Every javascript or HTML is file, based on extension
  def file?(path)
    [".js", ".html"].include?(File.extname(path))
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
      get_document_part(database, id, parts).to_s
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
  # every javascript file is writable
  def can_write?(path)
    File.extname(path) == ".js"
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

  # gets the database, id and parts from path
  def extract_parts(path)
    database, id, *parts = scan_path(path)
    if id == "_design" && !parts.empty?
      id << "/#{parts.shift}"
    end
    [database, id] + parts
  end

  # get document 'id' from 'database',
  # or a part of the document.
  def get_document_part(database, id, parts = [])
    doc = db.get_document(database, id)
    parts.each do |part|
      doc = doc ? doc[remove_extname(part)] : nil
    end
    doc
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
    filename.sub(/((\.(f|i))?\.js|\.html)\z/, "")
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
end
