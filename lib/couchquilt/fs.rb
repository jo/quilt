require 'cgi'
require 'uri'

module Couchquilt
  class FS
    # initializes Quilt FS with the database server name
    def initialize(server_name)
      @couch = CouchClient.new(server_name)
    end

    # list contents of path
    def contents(path)
      database, id, *parts = extract_parts(path)
  
      list case named_path(path)
           when :root
             @couch.get("_all_dbs")
           when :database
             ["_design"] +
               # database meta data
               map_json(@couch.get(database)) +
               # all documents but design documents
               # Note: we can not use ?startkey="_design/"&endkey="_design0" here,
               # because that would return no results for databases without design documents
               @couch.get("#{database}/_all_docs")["rows"].map { |r| r["id"] }.select { |id| id !~ /^_design\// }
           when :_design
             query = URI.encode('startkey="_design"&endkey="_design0"')
             # all design documents
             @couch.get("#{database}/_all_docs?#{query}")["rows"].map { |r| r["id"].sub("_design/", "") }
           when :_show
             (@couch.get("#{database}/#{id}")["shows"] || {}).keys
           when :_list
             (@couch.get("#{database}/#{id}")["lists"] || {}).keys
           when :_view
             (@couch.get("#{database}/#{id}")["views"] || {}).keys
           when :list_function
             (@couch.get("#{database}/#{id}")["views"] || {}).keys.map { |name| "#{name}.html" }
           when :show_function
             query = URI.encode('startkey="_design0"')
             @couch.get("#{database}/_all_docs?#{query}")["rows"].map { |r| "#{r["id"]}.html" }
           when :view_function, :view_function_result
             map_json(get_view_result_part(database, id, parts))
           when :design_document
             ["_list", "_show", "_view"] +
               map_json(get_document_part(database, id))
           else
             map_json(get_document_part(database, id, parts))
           end
    end
  
    # is path a directory?
    def directory?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :database, :document, :design_document
        @couch.head(path)
      when :view_function_result
        doc = get_view_result_part(database, id, parts)
        # arrays and hashes are mapped into directories
        doc.is_a?(Hash) || doc.is_a?(Array)
      when :database_info, :show_function_result, :list_function_result
        false
      when nil
        # look into document
        doc = get_document_part(database, id, parts)
        # arrays and hashes are mapped into directories
        doc.is_a?(Hash) || doc.is_a?(Array)
      else
        # all other special paths are directories by now
        # TODO: thats not so good.
        true
      end
    end
  
    # is path a file?
    def file?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :database_info, :show_function_result, :list_function_result
        true
      when :view_function_result
        # Every javascript or HTML is file, based on extension
        [".js", ".html"].include?(File.extname(path))
      when nil
        # look into document
        doc = get_document_part(database, id, parts)
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
                @couch.get(database)[remove_extname(id)]
              when :show_function_result
                parts.shift
                @couch.get(remove_extname(File.join(database, id, "_show", *parts)))
              when :list_function_result
                parts.shift
                @couch.get(remove_extname(File.join(database, id, "_list", *parts)))
              when :view_function_result
                get_view_result_part(database, id, parts)
              else
                get_document_part(database, id, parts)
              end
    end
  
    # is path writable?
    # every javascript file is writable, except ones starting with an underscore
    def can_write?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :switch_delete_database, :switch_delete_document
        true
      when :database_info, :show_function_result, :list_function_result, :view_function_result
        false
      else
        File.basename(path) !~ /\A_/ && File.extname(path) == ".js"
      end
    end
  
    # writes content str to path
    def write_to(path, str)
      database, id, *parts = extract_parts(path)
      # fetch document
      doc = @couch.get("#{database}/#{id}")
      # update the value that the file at path holds
      update_value(doc, parts, str)
      # save document
      @couch.put("#{database}/#{id}", doc)
    end
  
    # can I delete path?
    def can_delete?(path)
      return false if File.basename(path) =~ /\A_/
  
      case named_path(path)
      when :database_info, :show_function_result, :list_function_result, :view_function_result
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
      doc = @couch.get("#{database}/#{id}")
      # remove object
      remove_object(doc, parts)
      # save document
      @couch.put("#{database}/#{id}", doc)
    end
  
    # can I make a directory at path?
    def can_mkdir?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :root, :_design, :_list, :list_function, :_show, :show_function, :_view, :view_function, :view_function_result
        false
      when :database, :document, :design_document
        # can create database or document unless exists
        !@couch.head(path)
      else
        !get_document_part(database, id, parts)
      end
    end
  
    # makes a directory
    # this creates either a database, a document or inserts an object into a document
    def mkdir(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :database
        @couch.put(database)
      when :document, :design_document
        @couch.put("#{database}/#{id}")
      else
        # fetch document
        doc = @couch.get("#{database}/#{id}")
        # insert empty object
        update_value(doc, parts, {})
        # save document
        @couch.put("#{database}/#{id}", doc)
      end
    end
  
    # can I remove a directory at path?
    def can_rmdir?(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :root, :_design, :_list, :list_function, :_show, :show_function, :_view, :view_function, :view_function_result, :database, :document, :design_document
        false
      else
        get_document_part(database, id, parts).empty? rescue nil
      end
    end
  
    # deletes a directory
    # that is a part of a document
    def rmdir(path)
      database, id, *parts = extract_parts(path)
  
      # fetch document
      doc = @couch.get("#{database}/#{id}")
      # remove object
      update_value(doc, parts, nil)
      # save document
      @couch.put("#{database}/#{id}", doc)
    end
  
    # switch to delete a database or document
    def touch(path)
      database, id, *parts = extract_parts(path)
  
      case named_path(path)
      when :switch_delete_database
        @couch.delete(database)
      when :switch_delete_document
        doc = @couch.get("#{database}/#{id}")
        @couch.delete("#{database}/#{id}?rev=#{doc["_rev"]}")
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
        nil
      end
    end
  
    # maps json contents into contents array
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
  
    # fetch part of document
    def get_document_part(database, id, parts = [])
      doc = @couch.get("#{database}/#{id}")
      get_part(doc, parts)
    end
  
    # get view result, or a part of that document.
    def get_view_result_part(database, id, parts = [])
      a, view_function_name, *rest = parts
      view = [id.sub("_design/", ""), "_view", view_function_name].join("/")
      doc = @couch.get("#{database}/_design/#{view}")
      get_part(doc, rest)
    end
  
    # get a part of the document
    # eg: get_part({ :a => { :b => :c}}, [:a, :b]) #=> :c
    # also removes the file extension and gets index of arrays
    def get_part(doc, parts)
      return if doc.nil?
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
  
    # removes an object from a hash
    # Example:
    #  remove_object({:a => { :b => 'c'}}, [:a, :b]) #=> {:a => { }}
    def remove_object(hash, keys)
      key = remove_extname(keys.shift)
      if keys.empty?
        hash.delete(key)
      else
        hash[key] = remove_object(hash[key], keys)
      end
      hash
    end
  
    # remove extname to get the id
    def remove_extname(filename)
      filename.sub(/((\.(f|i|b))?\.js|\.html)\z/, "")
    end
  
    # Appends extname, that is: builds a filename from key and value.
    # Note: values are casted by extension.
    def append_extname(key, value)
      basename = key.is_a?(Integer) ? "%di" % key : key
  
      case value
      when Float
        "#{basename}.f.js"
      when Integer
        "#{basename}.i.js"
      when nil, String
        "#{basename}.js"
      when true, false
        "#{basename}.b.js"
      else
        basename
      end
    end

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
