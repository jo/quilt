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
      list_design_documents
    elsif rest.empty?
      ["views", "_rev"]
    elsif rest == ["views"]
      list_views(base)
    elsif rest.size == 2 && rest.first == "views"
      ["map.js", "reduce.js"]
    else
      []
    end
  end

  def file?(path)
    base, *rest = scan_path(path)
    # /Site/_rev
    # /Site/views/by_name/map.js
    # /Site/views/by_name/reduce.js
    rest == ["_rev"] ||
      rest.size == 3 && rest[0] == "views" && ["map.js", "reduce.js"].include?(rest.last)
  end

  def directory?(path)
    base, *rest = scan_path(path)
    # /Site
    # /Site/views
    # /Site/views/by_name
    rest.empty? || rest == ["views"] || (rest.size == 2 && rest.first == "views")
  end

  def executable?(path)
    return false if file?(path)
  end

  def read_file(path)
    return unless file?(path)
    parts = scan_path(path)
    read_content_for parts
  end

  def write_to(path, str)
    return unless file?(path)
    parts = scan_path(path)
    write_content_to parts, str
    true
  end

  private

  def list_design_documents
    docs = @db.documents :startkey => "_design/", :endkey => "_design/_", :include_docs => true
    docs.is_a?(Hash) ? docs["rows"].map { |doc| design_document_name(doc["id"]) }.sort : []
  end

  def list_views(name)
    doc = get_design_document(name)
    doc["views"].keys.sort
  end

  def read_content_for(parts)
    name = parts.shift
    result = get_design_document(name)
    parts.each do |part|
      p = part.sub(/\.js\z/, "")
      result = result[p]
    end
    result
  end

  def write_content_to(parts, str)
    puts parts.inspect
    puts str
  end

  def get_design_document(name)
    @db.get "_design/#{name}"
  end

  def design_document_name(id)
    id.split("/").last
  end
end
