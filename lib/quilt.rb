# Quilt mixes CouchDB Design Documents into the filesystem provided by FuseFS::MetaDir.
#
# Directory Structure:
# /
#   ApplictionName
#     _rev.js
#     _id.js
#     views
#       view_name
#         map.js
#         reduce.js

require 'rubygems'
require 'couchrest'

class Quilt < FuseFS::FuseDir
  def initialize(db_server)
    @db_server = db_server
  end

  def contents(path)
    base, *rest = scan_path(path)
    if base.nil?
      list_databases
    elsif rest.empty?
      list_documents(base)
    elsif rest == ["_design"]
      list_design_documents(base)
    else
      list_document_content(path)
    end
  end

  def file?(path)
    File.extname(path) == ".js"
  end


  def directory?(path)
    base, *parts = scan_path(path)
    return true if parts == ["_design"]
    if parts.empty?
      res = read_database(base)
      res.is_a?(Hash) || res.is_a?(Array)
    else
      res = read_document(path)
      res.is_a?(Hash) || res.is_a?(Array)
    end
  end

  def read_file(path)
    read_document(path).to_s
  end

  def can_write?(path)
    file?(path)
  end

  def write_to(path, str)
    db_name, id, *parts = id_and_parts_from(path)
    doc = db(db_name).get(id)
    update_value(doc, parts, str)
    db(db_name).save_doc doc
  end

  def can_delete?(path)
    # This helps editors, but we don't really use it.
    true
  end

  private

  def db(name)
    CouchRest.database(File.join(@db_server, name))
  end

  def update_value(hash, keys, value)
    key = id_for(keys.shift)
    if keys.empty?
      hash[key] = value
    else
      hash[key] = update_value(hash[key], keys, value)
    end
    hash
  end

  def list_databases
    CouchRest.get File.join(@db_server, "_all_dbs")
  rescue => e
    puts e.message
  end

  def list_documents(database)
    ["_design"] + db(database).documents["rows"].map { |doc| doc["id"] }.select { |e| e !~ /\A_design\// }
  end

  def list_design_documents(database)
    db(database).documents(:startkey => "_design/", :endkey => "_design/_")["rows"].map { |doc| doc["id"].sub(/\A_design\//, "") }
  end

  def get_document(database, id, parts = [])
    doc = db(database).get(id)
    parts.each do |part|
      doc = doc[id_for(part)]
    end
    doc
  end

  def list_document_content(path)
    database, id, *parts = id_and_parts_from(path)
    doc = get_document(database, id, parts)
    if doc.is_a?(Hash)
      doc.keys.sort.map { |k| filename_for(k, doc[k]) }
    elsif doc.is_a?(Array)
      doc.map { |k| filename_for(k, doc[k]) }
    else
      []
    end
  end

  def read_database(name)
    CouchRest.get File.join(@db_server, name)
  end

  def read_document(path)
    database, id, *parts = id_and_parts_from(path)
    get_document(database, id, parts)
  end

  def id_for(filename)
    filename.sub(/(\.(f|i))?\.js\z/, "")
  end

  def filename_for(key, value)
    name = key.dup
    if value.is_a?(Float)
      name << ".f.js"
    elsif value.is_a?(Integer)
      name << ".i.js"
    elsif value.is_a?(String)
      name << ".js"
    end
    name
  end

  def id_and_parts_from(path)
    database, name, *parts = scan_path(path)
    if name == "_design"
      raise "Design document name incomplete" if parts.empty?
      name << "/#{parts.shift}"
    end
    [database] + [name] + parts
  end
end
