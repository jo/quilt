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
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :root
      db.databases
    when :database
      ["_design"] + db.documents(database)
    when :_design
      db.design_documents(database)
    when :_show
      doc = get_document_part(database, id, ["shows"])
      doc.keys.sort
    when :_list
      doc = get_document_part(database, id, ["lists"])
      doc.keys.sort
    when :_view
      doc = get_document_part(database, id, ["views"])
      doc.keys.sort
    when :list_function
      doc = get_document_part(database, id, ["views"])
      doc.keys.sort.map { |name| "#{name}.html" }
    when :show_function
      db.documents(database).map { |name| "#{name}.html" }
    when :view_function, :view_function_result
      list_view_result(database, id, parts)
    when :design_document
      (list_document(database, id, parts) + ["_list", "_show", "_view"]).sort
    else
      list_document(database, id, parts)
    end

  rescue => e
    puts e.message, e.backtrace
  end

  # is path a directory?
  def directory?(path)
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :view_function_result
      doc = get_view_result_part(database, id, parts)
      # arrays and hashes are mapped into directories
      doc.is_a?(Hash) || doc.is_a?(Array)
    when nil
      # look into document
      doc = get_document_part(database, id, parts)
      # arrays and hashes are mapped into directories
      doc.is_a?(Hash) || doc.is_a?(Array)
    when :show_function_result, :list_function_result
      false
    when :database
      db.database?(database)
    when :document
      db.document?(database, id)
    else
      # all other special paths are directories by now
      true
    end

  rescue => e
    puts e.message, e.backtrace
  end

  # is path a file?
  def file?(path)
    case special_pathname(path)
    when nil, :view_function_result
      # Every javascript or HTML is file, based on extension
      [".js", ".html"].include?(File.extname(path))
    when :show_function_result, :list_function_result
      true
    else
      false
    end
  end

  # reading file contents of path
  def read_file(path)
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :show_function_result
      parts.shift
      filename = File.join(@server_name, database, id, "_show", parts)
      file = open(remove_extname(filename))
      file.read if file
    when :list_function_result
      parts.shift
      filename = File.join(@server_name, database, id, "_list", parts)
      file = open(remove_extname(filename))
      file.read if file
    when :view_function_result
      get_view_result_part(database, id, parts).to_s
    else
      get_document_part(database, id, parts).to_s
    end

  rescue => e
    puts e.message, e.backtrace
  end

  # is path writable?
  # every javascript file is writable, except ones starting with an underscore
  def can_write?(path)
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :show_function_result, :list_function_result, :view_function_result
      false
    else
      File.basename(path) !~ /\A_/ && File.extname(path) == ".js"
    end
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

  def can_mkdir?(path)
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :root, :_design, :_list, :list_function, :_show, :show_function, :_view, :view_function, :view_function_result
      false
    when :database
      !db.database?(database)
    when :design_document, :document
      !db.document?(database, id)
    else
      !get_document_part(database, id, parts)
    end

  rescue => e
    puts e.message, e.backtrace
  end

  def mkdir(path)
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :database
      puts "create db"
    when :document, :design_document
      puts "create document"
    else
      puts "create property"
    end

  rescue => e
    puts e.message, e.backtrace
  end

  def can_rmdir?(path)
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :root, :_design, :_list, :list_function, :_show, :show_function, :_view, :view_function, :view_function_result
      false
    when :database
      db.database?(database)
    when :document, :design_document
      db.document?(database, id)
    else
      get_document_part(database, id, parts).empty? rescue nil
    end

  rescue => e
    puts e.message, e.backtrace
  end

  def rmdir(path)
    database, id, *parts = extract_parts(path)

    case special_pathname(path)
    when :database
      puts "delete db"
    when :document, :design_document
      puts "delete document"
    else
      puts "delete property"
    end

  rescue => e
    puts e.message, e.backtrace
  end

  private

  # list contents of document and maps json
  def list_document(database, id, parts = [])
    doc = get_document_part(database, id, parts)

    map_json(doc)
  end

  def list_view_result(database, id, parts = [])
    doc = get_view_result_part(database, id, parts)

    map_json(doc)
  end

  def map_json(doc)
    case doc
    when Hash
      # Hash is mapped to directory
      doc.keys.sort.map { |k| append_extname(k, doc[k]) }
    when Array
      # Array is mapped to directory
      doc.map { |k| append_extname(doc.index(k), k) }
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

  # returns a path identifier for special paths
  def special_pathname(path)
    database, id, *parts = extract_parts(path)

    if database.nil?
      # /
      :root
    elsif id.nil?
      # /database_id
      :database
    elsif id == "_design" && parts.empty?
      # /database_id/_design
      :_design
    elsif id =~ /_design\// && parts.empty?
      # /database_id/_design/design_document_id
      :design_document
    elsif id =~ /_design\// && parts == ["_show"]
      # /database_id/_design/design_document_id/_show
      :_show
    elsif id =~ /_design\// && parts == ["_list"]
      # /database_id/_design/design_document_id/_list
      :_list
    elsif id =~ /_design\// && parts == ["_view"]
      # /database_id/_design/design_document_id/_view
      :_view
    elsif id =~ /_design\// && parts.size == 2 && parts.first == "_list"
      # /database_id/_design/design_document_id/_list/list_function_name
      :list_function
    elsif id =~ /_design\// && parts.size == 3 && parts.first == "_list"
      # /database_id/_design/design_document_id/_list/list_function_name/view_function_name
      :list_function_result
    elsif id =~ /_design\// && parts.size == 2 && parts.first == "_show"
      # /database_id/_design/design_document_id/_show/show_function_name
      :show_function
    elsif id =~ /_design\// && parts.size == 3 && parts.first == "_show"
      # /database_id/_design/design_document_id/_show/show_function_name/document_id
      :show_function_result
    elsif id =~ /_design\// && parts.size == 2 && parts.first == "_view"
      # /database_id/_design/design_document_id/_view/view_function_name
      :view_function
    elsif id =~ /_design\// && parts.size >= 3 && parts.first == "_view"
      # /database_id/_design/design_document_id/_view/view_function_name/document_id
      :view_function_result
    elsif parts.empty?
      # /database_id/document_id
      :document
    else
      # /database_id/document_id/object
      # /database_id/_design/design_document_id
      # /database_id/_design/design_document_id/object
      nil # path.to_sym
    end
  end

  # get document 'id' from 'database',
  # or a part of the document.
  def get_document_part(database, id, parts = [])
    doc = db.get_document(database, id)
    get_part(doc, parts)
  end

  # get view result, or a part of that document.
  def get_view_result_part(database, id, parts = [])
    a, view_function_name, *rest = parts
    view_id = [id.sub("_design/", ""), view_function_name].join("/")
    doc = db.get_view(database, view_id)
    get_part(doc, rest)
  end

  def get_part(doc, parts)
    doc = doc.dup
    parts.each do |part|
      case doc
      when Hash
        doc = doc[remove_extname(part)]
      when Array
        doc = doc[part.to_i]
      end
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

    case value
    when Float
      "#{basename}.f.js"
    when Integer
      "#{basename}.i.js"
    when nil, String
      "#{basename}.js"
    else
      basename
    end
  end
end
