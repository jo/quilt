module Couchquilt
  module Database
    ## database queries
    
    # does a database, document or design_document exists?
    def exists?(path)
      @couch.head key_for(path)
    end

    # query for all dbs
    def all_dbs
      @couch.get("_all_dbs")
    end

    # query for database info
    def database_info(database, parts = [])
      @couch.get(database).at_path(parts)
    end

    # query for all docs ids
    def all_doc_ids(database, query_string = nil)
      path = "#{database}/_all_docs"
      path << "?#{URI.encode query_string}" if query_string
      @couch.get(path)["rows"].map { |r| r["id"] }
    end

    # query for document
    def document(database, id, parts = [])
      @couch.get("#{database}/#{id}").at_path(parts)
    end

    # query for view
    def view(database, id, parts)
      a, view_function_name, *rest = parts
      query = [id.sub("_design/", ""), "_view", view_function_name].join("/")
      doc = @couch.get("#{database}/_design/#{query}").at_path(rest)
    end

    # query a function
    def function_result(database, id, parts)
      @couch.get key_for(File.join(database, id, *parts))
    end

    ## document manipulation

    # updating documents
    def update(database, id, doc)
      @couch.put("#{database}/#{id}", doc)
    end

    # create database or document
    def create(database, id = nil)
      @couch.put("#{database}/#{id}")
    end

    # delete a database
    def delete_database(database)
      @couch.delete(database)
    end

    # delete a document
    def delete_document(database, id)
      doc = document(database, id)
      @couch.delete("#{database}/#{id}?rev=#{doc["_rev"]}")
    end
  end
end
