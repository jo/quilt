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
  def initialize(db)
    @db = CouchRest.database(db)
  end

  def contents(path)
    base, *rest = scan_path(path)
    if base.nil?
      list_documents
    elsif base == "_design" && rest.empty?
      list_design_documents
    else
      list_document_content(path)
    end
  end

  def file?(path)
    File.extname(path) == ".js"
  end


  def directory?(path)
    return true if path == "/_design"
    res = read_document(path)
    res.is_a?(Hash) || res.is_a?(Array)
  end

  def read_file(path)
    read_document(path).to_s
  end

  def can_write?(path)
    file?(path)
  end

  def write_to(path, str)
    id, *parts = id_and_parts_from(path)
    doc = @db.get(id)
    update_value(doc, parts, str)
    @db.save_doc doc
  end

  def can_delete?(path)
    # This helps editors, but we don't really use it.
    true
  end

  private

  def update_value(hash, keys, value)
    key = id_for(keys.shift)
    if keys.empty?
      hash[key] = value
    else
      hash[key] = update_value(hash[key], keys, value)
    end
    hash
  end

  def list_documents
    ["_design"] + @db.documents["rows"].map { |doc| doc["id"] }.select { |e| e !~ /\A_design\// }
  end

  def list_design_documents
    @db.documents(:startkey => "_design/", :endkey => "_design/_")["rows"].map { |doc| doc["id"].sub(/\A_design\//, "") }
  end

  def get_document(id, parts = [])
    doc = @db.get(id)
    parts.each do |part|
      doc = doc[id_for(part)]
    end
    doc
  end

  def list_document_content(path)
    id, *parts = id_and_parts_from(path)
    doc = get_document(id, parts)
    if doc.is_a?(Hash)
      doc.keys.sort.map { |k| filename_for(k, doc[k]) }
    elsif doc.is_a?(Array)
      doc.map { |k| filename_for(k, doc[k]) }
    else
      []
    end
  end

  def read_document(path)
    id, *parts = id_and_parts_from(path)
    get_document(id, parts)
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
    name, *parts = scan_path(path)
    if name == "_design"
      raise "Design document name incomplete" if parts.empty?
      name << "/#{parts.shift}"
    end
    [name] + parts
  end
end
