require 'rubygems'
require 'couchrest'

class QuiltDB
  # initializes QuiltDB with database server name
  def initialize(db_server = "http://127.0.0.1:5984")
    @db_server = db_server
  end

  # list all databases
  def databases
    CouchRest.get File.join(@db_server, "_all_dbs")
  end

  # list all documents
  def documents(database)
    get_db(database).documents["rows"].map { |doc| doc["id"] }.select { |e| e !~ /\A_design\// }
  end

  # list all design documents
  def design_documents(database)
    get_db(database).documents(:startkey => "_design/", :endkey => "_design0")["rows"].map { |doc| doc["id"].sub(/\A_design\//, "") }
  end

  def get_document(database, id)
    get_db(database).get(id)
  end

  def get_view(database, id)
    get_db(database).view(id)
  end

  def save_document(database, doc)
    get_db(database).save_doc doc
  end

  private

  # returns a Couchrest database object for database name
  def get_db(name)
    CouchRest.database(File.join(@db_server, name))
  end
end
