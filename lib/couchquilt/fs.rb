require 'cgi'
require 'uri'

module Couchquilt
  class FS
    include Mapper
    include Database

    # initializes Quilt FS with the database server name
    def initialize(server_name)
      @couch = CouchClient.new(server_name)
    end

    # list contents of path
    def contents(path)
      database, id, *parts = extract_parts(path)
  
      list case named_path(path)
           when :root
             ["_uuids"] + all_dbs
           when :uuids
             ["0i.js"]
           when :database
             ["_design"] +
               # database meta data
                database_info(database, id).to_fs +
               # all documents but design documents
               all_doc_ids(database).select { |id| id !~ /^_design\// }
           when :_design
             # all design documents
             all_doc_ids(database, 'startkey="_design"&endkey="_design0"').map { |id| id.sub("_design/", "") }
           when :_show
             document(database, id, "shows").to_fs(false)
           when :_list
             document(database, id, "lists").to_fs(false)
           when :_view
             document(database, id, "views").to_fs(false)
           when :list_function
             document(database, id, "views").to_fs(false).map { |name| "#{name}.html" }
           when :show_function
             all_doc_ids(database, 'startkey="_design0"').map { |id| "#{id}.html" }
           when :view_function, :view_function_result
             view(database, id, parts).to_fs
           when :design_document
             ["_list", "_show", "_view"] +
               document(database, id).to_fs
           else
             document(database, id, parts).to_fs
           end
    end
  
    # is path a directory?
    def directory?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :database, :document, :design_document
        exists?(path)
      when :view_function_result
        doc = view(database, id, parts)
        # arrays and hashes are mapped into directories
        doc.is_a?(Hash) || doc.is_a?(Array)
      when :database_info, :show_function_result, :list_function_result, :uuid
        false
      when :document_part
        # look into document
        doc = document(database, id, parts)
        # arrays and hashes are mapped into directories
        doc.is_a?(Hash) || doc.is_a?(Array)
      else
        # all other special paths are directories by now
        # TODO: thats not very good.
        true
      end
    end
  
    # is path a file?
    def file?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :database_info, :show_function_result, :list_function_result, :uuid
        true
      when :view_function_result
        # Every javascript or HTML is a file, based on extension
        [".js", ".html"].include?(File.extname(path))
      when :document_part
        # look into document
        doc = document(database, id, parts)
        # only arrays and hashes are mapped into directories
        !doc.nil? && !(doc.is_a?(Hash) || doc.is_a?(Array))
      else
        false
      end
    end
  
    # reading file contents of path
    def read_file(path)
      database, id, *parts = extract_parts(path)
  
      content case named_path(path)
              when :database_info
                database_info(database, id)
              when :show_function_result, :list_function_result
                function_result(database, id, parts)
              when :view_function_result
                view(database, id, parts)
              when :uuid
                document(database, id, "uuids")
              else
                document(database, id, parts)
              end
    end
  
    # is path writable?
    # every javascript file is writable, except ones starting with an underscore
    def can_write?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :switch_delete_database, :switch_delete_document
        true
      when :database_info, :show_function_result, :list_function_result, :view_function_result, :uuid
        false
      else
        File.basename(path) !~ /\A_/ && File.extname(path) == ".js"
      end
    end
  
    # writes content str to path
    def write_to(path, str)
      str.strip!
      database, id, *parts = extract_parts(path)
      # fetch document
      doc = document(database, id)
      # update the value that the file at path holds
      doc.update_at_path(parts, str)
      # save document
      update(database, id, doc)
    end
  
    # can I delete path?
    def can_delete?(path)
      return false if File.basename(path) =~ /\A_/
  
      case named_path(path)
      when :database_info, :show_function_result, :list_function_result, :view_function_result, :uuid
        false
      else
        true
      end
    end
  
    # deletes path
    # either deletes a database, document or removes a part of a document
    def delete(path)
      database, id, *parts = extract_parts(path)
  
      # fetch document
      doc = document(database, id)
      # remove object
      doc.delete_at_path(parts)
      # save document
      update(database, id, doc)
    end
  
    # can I make a directory at path?
    def can_mkdir?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :root, :_design, :_list, :list_function, :_show, :show_function, :_view, :view_function, :view_function_result
        false
      when :database, :document, :design_document
        # can create database or document unless exists
        !exists?(path)
      else
        !document(database, id, parts)
      end
    end
  
    # makes a directory
    # this creates either a database, a document or inserts an object into a document
    def mkdir(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :database
        create(database)
      when :document, :design_document
        create(database, id)
      else
        # fetch document
        doc = document(database, id)
        # insert empty object
        doc.update_at_path(parts, {})
        # save document
        update(database, id, doc)
      end
    end
  
    # can I remove a directory at path?
    def can_rmdir?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :root, :_design, :_list, :list_function, :_show, :show_function, :_view, :view_function, :view_function_result, :database, :document, :design_document
        false
      else
        document(database, id, parts).empty? rescue false
      end
    end
  
    # deletes a directory
    # that is a part of a document
    def rmdir(path)
      database, id, *parts = extract_parts(path)
  
      # fetch document
      doc = document(database, id)
      # remove object
      doc.delete_at_path(parts)
      # save document
      update(database, id, doc)
    end
  
    # switch to delete a database or document
    def touch(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :switch_delete_database
        delete_database(database)
      when :switch_delete_document
        delete_document(database, id)
      end
    end
  
    private
  
    # gets the database, id and parts from path
    def extract_parts(path)
      database, id, *parts = path.scan(/[^\/]+/)
      if id == "_design" && !parts.empty?
        id << "/#{parts.shift}"
      end
      [database, id] + parts
    end
  
    # returns a path identifier for special paths
    def named_path(path)
      database, id, *parts = extract_parts(path)
  
      if database.nil?
        # /
        :root
      elsif database == "_uuids" && id.nil?
        :uuids
      elsif database == "_uuids"
        :uuid
      elsif id == "_delete"
        :switch_delete_database
      elsif parts.size == 1 && parts.first == "_delete"
        :switch_delete_document
      elsif id.nil?
        # /database_id
        :database
      elsif ["compact_running.b.js", "db_name.js", "disk_format_version.i.js", "disk_size.i.js", "doc_count.i.js", "doc_del_count.i.js", "instance_start_time.js", "purge_seq.i.js", "update_seq.i.js"].include?(id) && parts.empty?
        :database_info
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
        :document_part
      end
    end


    ## list and content helper

    # escapes the value for using as filename
    def list(array)
      return [] if array.nil?
      array.compact.map { |v| CGI.escape(v) }.sort
    end

    def content(value)
      value.to_s
    end
  end
end
