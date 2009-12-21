require File.join(File.dirname(__FILE__), 'spec_helper.rb')

# Note: databases, documents and keys with slashes are not supported by now
require 'rubygems'
require 'couchrest'

describe "Quilt" do
  before do
    @quilt = Quilt.new 
    @database_id = "quilt-test-db"
    @server_name = @quilt.server_name
    CouchRest.delete(File.join(@server_name, @database_id)) rescue nil
    @db = CouchRest.database!(File.join(@server_name, @database_id))

    @document = {
      "_id" => "document_id",
      "name" => "This is a name",
      "integer" => 12,
      "float" => 1.2,
      "object" => { "key" => "this is a value" },
      "array" => ["this is another value"],
      "empty" => {}
    }
    @db.save_doc(@document)

    @design_document = {
      "_id" => "_design/design_document_id",
      "language" => "javascript",
      "name" => "This is a name",
      "shows" => {
        "show_function_name" => "function(doc, req) { return 'Hello World!'; }",
      },
      "lists" => {
        "list_function_name" => "function(head, req) { return 'Hello World!'; }",
      },
      "views" => {
        "view_function_name" => {
          "map" => "function(doc) { if(doc.name) { emit(doc.name, null); } }"
        }
      },
    }
    @db.save_doc(@design_document)
  end

  describe "/" do
    it "directory? should return true" do
      @quilt.directory?("/").should be_true
    end
    it "file? should return false" do
      @quilt.file?("/").should be_false
    end
    it "contents should list databases" do
      @quilt.contents("/").should include(@database_id)
    end
    it "can_mkdir? should return false" do
      @quilt.can_mkdir?("/").should be_false
    end
    it "can_rmdir? should return false" do
      @quilt.can_rmdir?("/").should be_false
    end

    # /unknown_database
    describe "unknown_database/" do
      it "directory? should return false" do
        @quilt.directory?("/unknown_database").should be_false
      end
      it "file? should return false" do
        @quilt.file?("/unknown_database").should be_false
      end
      it "can_mkdir? should return true" do
        @quilt.can_mkdir?("/unknown_database").should be_true
      end
      it "mkdir should create database"
    end

    # /database_id
    describe "database_id/" do
      it "directory? should return true" do
        @quilt.directory?("/#{@database_id}").should be_true
      end
      it "file? should return false" do
        @quilt.file?("/#{@database_id}").should be_false
      end
      it "contents should list documents" do
        @quilt.contents("/#{@database_id}").should == ["_design", "document_id"]
      end
      it "can_mkdir? should return false" do
        @quilt.can_mkdir?("/#{@database_id}").should be_false
      end
      it "can_rmdir? should return true" do
        @quilt.can_rmdir?("/#{@database_id}").should be_true
      end
      it "rmdir should delete document"

      # /database_id/unknown_document
      describe "unknown_document/" do
        it "directory? should return false" do
          @quilt.directory?("/#{@database_id}/unknown_document").should be_false
        end
        it "file? should return false" do
          @quilt.file?("/#{@database_id}/unknown_document").should be_false
        end
        it "can_mkdir? should return true" do
          @quilt.can_mkdir?("/#{@database_id}/unknown_document").should be_true
        end
        it "can_rmdir? should return false" do
          @quilt.can_rmdir?("/#{@database_id}/unknown_document").should be_false
        end
      end

      # /database_id/document_id
      describe "document_id/" do
        it "directory? should return true" do
          @quilt.directory?("/#{@database_id}/document_id").should be_true
        end
        it "file? should return false" do
          @quilt.file?("/#{@database_id}/document_id").should be_false
        end
        it "contents should list documents content" do
          @quilt.contents("/#{@database_id}/document_id").should == ["_id.js", "_rev.js", "array", "empty", "float.f.js", "integer.i.js", "name.js", "object"]
        end
        it "can_mkdir? should return false" do
          @quilt.can_mkdir?("/#{@database_id}/document_id").should be_false
        end
        it "can_rmdir? should return true" do
          @quilt.can_rmdir?("/#{@database_id}/document_id").should be_true
        end
        it "rmdir should delete database"
        
        # /database_id/document_id/unknown_attribute
        describe "unknown_attribute/" do
          it "directory? should return false" do
            @quilt.directory?("/#{@database_id}/document_id/unknown_attribute").should be_false
          end
          it "file? should return false" do
            @quilt.file?("/#{@database_id}/document_id/unknown_attribute").should be_false
          end
          it "can_mkdir? should return true" do
            @quilt.can_mkdir?("/#{@database_id}/document_id/unknown_attribute").should be_true
          end
          it "mkdir should update document"
        end

        # /database_id/document_id/_id.js
        describe "_id.js" do
          it "directory? should return false" do
            @quilt.directory?("/#{@database_id}/document_id/_id.js").should be_false
          end
          it "file? should return true" do
            @quilt.file?("/#{@database_id}/document_id/_id.js").should be_true
          end
          it "read_file should return contents" do
            @quilt.read_file("/#{@database_id}/document_id/_id.js").should == "document_id"
          end
          it "can_write? should return false" do
            @quilt.can_write?("/#{@database_id}/document_id/_id.js").should be_false
          end
          it "can_delete? should return false" do
            @quilt.can_delete?("/#{@database_id}/document_id/_id.js").should be_false
          end
        end

        # /database_id/document_id/name.js
        describe "name.js" do
          it "directory? should return false" do
            @quilt.directory?("/#{@database_id}/document_id/name.js").should be_false
          end
          it "file? should return true" do
            @quilt.file?("/#{@database_id}/document_id/name.js").should be_true
          end
          it "read_file should return contents" do
            @quilt.read_file("/#{@database_id}/document_id/name.js").should == @document["name"]
          end
          it "can_write? should return true" do
            @quilt.can_write?("/#{@database_id}/document_id/name.js").should be_true
          end
          it "write_to should update document" do
            @quilt.write_to("/#{@database_id}/document_id/name.js", "value").should be_true
          end
          it "can_delete? should return false" do
            @quilt.can_delete?("/#{@database_id}/document_id/name.js").should be_true
          end
          it "delete should update document"
        end

        # /database_id/document_id/object
        describe "object/" do
          it "directory? should return true" do
            @quilt.directory?("/#{@database_id}/document_id/object").should be_true
          end
          it "file? should return false" do
            @quilt.file?("/#{@database_id}/document_id/object").should be_false
          end
          it "contents should list object content" do
            @quilt.contents("/#{@database_id}/document_id/object").should == ["key.js"]
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?("/#{@database_id}/document_id/object").should be_false
          end
          it "can_rmdir? should return false when not empty" do
            @quilt.can_rmdir?("/#{@database_id}/document_id/object").should be_false
          end
        end
        
        # /database_id/document_id/array
        describe "array/" do
          it "directory? should return true" do
            @quilt.directory?("/#{@database_id}/document_id/array").should be_true
          end
          it "file? should return false" do
            @quilt.file?("/#{@database_id}/document_id/array").should be_false
          end
          it "contents should list array content" do
            @quilt.contents("/#{@database_id}/document_id/array").should == ["000.js"]
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?("/#{@database_id}/document_id/array").should be_false
          end
          it "can_rmdir? should return false when not empty" do
            @quilt.can_rmdir?("/#{@database_id}/document_id/array").should be_false
          end
        end
        
        # /database_id/document_id/empty
        describe "empty/" do
          it "directory? should return true" do
            @quilt.directory?("/#{@database_id}/document_id/empty").should be_true
          end
          it "file? should return false" do
            @quilt.file?("/#{@database_id}/document_id/empty").should be_false
          end
          it "contents should list empty content" do
            @quilt.contents("/#{@database_id}/document_id/empty").should == []
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?("/#{@database_id}/document_id/empty").should be_false
          end
          it "can_rmdir? should return true when empty" do
            @quilt.can_rmdir?("/#{@database_id}/document_id/empty").should be_true
          end
          it "rmdir should remove empty from dorument tree when empty"
        end
      end
      
      # /database_id/_design
      describe "_design/" do
        it "directory? should return true" do
          @quilt.directory?("/#{@database_id}/_design").should be_true
        end
        it "file? should return false" do
          @quilt.file?("/#{@database_id}/_design").should be_false
        end
        it "contents should list design documents" do
          @quilt.contents("/#{@database_id}/_design").should == ["design_document_id"]
        end
        it "can_mkdir? should return false" do
          @quilt.can_mkdir?("/#{@database_id}/_design").should be_false
        end
        it "can_rmdir? should return false" do
          @quilt.can_rmdir?("/#{@database_id}/_design").should be_false
        end
        
        # /database_id/_design/design_document_id
        describe "design_document_id/" do
          it "directory? should return true" do
            @quilt.directory?("/#{@database_id}/_design/design_document_id").should be_true
          end
          it "file? should return false" do
            @quilt.file?("/#{@database_id}/_design/design_document_id").should be_false
          end
          it "contents should list design documents content" do
            @quilt.contents("/#{@database_id}/_design/design_document_id").should == ["_id.js", "_list", "_rev.js", "_show", "_view", "language.js", "lists", "name.js", "shows", "views"]
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id").should be_false
          end
          it "can_rmdir? should return true" do
            @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id").should be_true
          end
          it "rmdir should remove design document"
          
          # /database_id/_design/design_document_id/_id.js
          describe "_id.js" do
            it "directory? should return false" do
              @quilt.directory?("/#{@database_id}/_design/design_document_id/_id.js").should be_false
            end
            it "file? should return true" do
              @quilt.file?("/#{@database_id}/_design/design_document_id/_id.js").should be_true
            end
            it "read_file should return value" do
              @quilt.read_file("/#{@database_id}/_design/design_document_id/_id.js").should == @design_document["_id"]
            end
            it "can_write? should return false" do
              @quilt.can_write?("/#{@database_id}/_design/design_document_id/_id.js").should be_false
            end
            it "can_delete? should return false" do
              @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_id.js").should be_false
            end
          end
          
          # /database_id/_design/design_document_id/name.js
          describe "name.js" do
            it "directory? should return false" do
              @quilt.directory?("/#{@database_id}/_design/design_document_id/name.js").should be_false
            end
            it "file? should return true" do
              @quilt.file?("/#{@database_id}/_design/design_document_id/name.js").should be_true
            end
            it "read_file should return value" do
              @quilt.read_file("/#{@database_id}/_design/design_document_id/name.js").should == @design_document["name"]
            end
            it "can_write? should return true" do
              @quilt.can_write?("/#{@database_id}/_design/design_document_id/name.js").should be_true
            end
            it "write_to should update _design/design_document_id" do
              @quilt.write_to("/#{@database_id}/_design/design_document_id/name.js", "value").should be_true
            end
            it "can_delete? should return true" do
              @quilt.can_delete?("/#{@database_id}/_design/design_document_id/name.js").should be_true
            end
            it "delete should update design document"
          end
          
          # /database_id/_design/design_document_id/_list
          describe "_list/" do
            it "directory? should return true" do
              @quilt.directory?("/#{@database_id}/_design/design_document_id/_list").should be_true
            end
            it "file? should return false" do
              @quilt.file?("/#{@database_id}/_design/design_document_id/_list").should be_false
            end
            it "contents should list list functions" do
              @quilt.contents("/#{@database_id}/_design/design_document_id/_list").should == ["list_function_name"]
            end
            it "can_mkdir? should return false" do
              @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_list").should be_false
            end
            it "can_rmdir? should return false" do
              @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_list").should be_false
            end
            
            # /database_id/_design/design_document_id/_list/list_function_name
            describe "list_function_name/" do
              it "directory? should return true" do
                @quilt.directory?("/#{@database_id}/_design/design_document_id/_list/list_function_name").should be_true
              end
              it "file? should return false" do
                @quilt.file?("/#{@database_id}/_design/design_document_id/_list/list_function_name").should be_false
              end
              it "contents should list views" do
                @quilt.contents("/#{@database_id}/_design/design_document_id/_list/list_function_name").should == ["view_function_name.html"]
              end
              it "can_mkdir? should return false" do
                @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_list/list_function_name").should be_false
              end
              it "can_rmdir? should return false" do
                @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_list/list_function_name").should be_false
              end
              
              # /database_id/_design/design_document_id/_list/list_function_name/view_function_name.html
              describe "view_function_name.html" do
                it "directory? should return false" do
                  @quilt.directory?("/#{@database_id}/_design/design_document_id/_list/list_function_name/view_function_name.html").should be_false
                end
                it "file? should return true" do
                  @quilt.file?("/#{@database_id}/_design/design_document_id/_list/list_function_name/view_function_name.html").should be_true
                end
                it "read_file should return contents" do
                  @quilt.read_file("/#{@database_id}/_design/design_document_id/_list/list_function_name/view_function_name.html").should == "Hello World!"
                end
                it "can_write? should return false" do
                  @quilt.can_write?("/#{@database_id}/_design/design_document_id/_list/list_function_name/view_function_name.html").should be_false
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_list/list_function_name/view_function_name.html").should be_false
                end
              end
            end
          end
          
          # /database_id/_design/design_document_id/_show
          describe "_show/" do
            it "directory? should return true" do
              @quilt.directory?("/#{@database_id}/_design/design_document_id/_show").should be_true
            end
            it "file? should return false" do
              @quilt.file?("/#{@database_id}/_design/design_document_id/_show").should be_false
            end
            it "contents should list show functions" do
              @quilt.contents("/#{@database_id}/_design/design_document_id/_show").should == ["show_function_name"]
            end
            it "can_mkdir? should return false" do
              @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_show").should be_false
            end
            it "can_rmdir? should return false" do
              @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_show").should be_false
            end
            
            # /database_id/_design/design_document_id/_show/show_function_name
            describe "show_function_name/" do
              it "directory? should return true" do
                @quilt.directory?("/#{@database_id}/_design/design_document_id/_show/show_function_name").should be_true
              end
              it "file? should return false" do
                @quilt.file?("/#{@database_id}/_design/design_document_id/_show/show_function_name").should be_false
              end
              it "contents should list documents" do
                @quilt.contents("/#{@database_id}/_design/design_document_id/_show/show_function_name").should == ["document_id.html"]
              end
              it "can_mkdir? should return false" do
                @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_show/show_function_name").should be_false
              end
              it "can_rmdir? should return false" do
                @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_show/show_function_name").should be_false
              end
              
              # /database_id/_design/design_document_id/_show/show_function_name/document_id.html
              describe "document_id.html" do
                it "directory? should return false" do
                  @quilt.directory?("/#{@database_id}/_design/design_document_id/_show/show_function_name/document_id.html").should be_false
                end
                it "file? should return true" do
                  @quilt.file?("/#{@database_id}/_design/design_document_id/_show/show_function_name/document_id.html").should be_true
                end
                it "read_file should return contents" do
                  @quilt.read_file("/#{@database_id}/_design/design_document_id/_show/show_function_name/document_id.html").should == "Hello World!"
                end
                it "can_write? should return false" do
                  @quilt.can_write?("/#{@database_id}/_design/design_document_id/_show/show_function_name/document_id.html").should be_false
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_show/show_function_name/document_id.html").should be_false
                end
              end
            end
          end
          
          # /database_id/_design/design_document_id/_view
          describe "_view/" do
            it "directory? should return true" do
              @quilt.directory?("/#{@database_id}/_design/design_document_id/_view").should be_true
            end
            it "file? should return false" do
              @quilt.file?("/#{@database_id}/_design/design_document_id/_view").should be_false
            end
            it "contents should list view functions" do
              @quilt.contents("/#{@database_id}/_design/design_document_id/_view").should == ["view_function_name"]
            end
            it "can_mkdir? should return false" do
              @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_view").should be_false
            end
            it "can_rmdir? should return false" do
              @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_view").should be_false
            end
            
            # /database_id/_design/design_document_id/_view/view_function_name
            describe "view_function_name/" do
              it "directory? should return true" do
                @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name").should be_true
              end
              it "file? should return false" do
                @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name").should be_false
              end
              it "contents should list view result document contents" do
                @quilt.contents("/#{@database_id}/_design/design_document_id/_view/view_function_name").should == ["offset.i.js", "rows", "total_rows.i.js"]
              end
              it "can_mkdir? should return false" do
                @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_view/view_function_name").should be_false
              end
              it "can_rmdir? should return false" do
                @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_view/view_function_name").should be_false
              end
              describe "offset.i.js" do
                it "directory? should return false" do
                  @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name/offset.i.js").should be_false
                end
                it "file? should return true" do
                  @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name/offset.i.js").should be_true
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_view/view_function_name/offset.i.js").should be_false
                end
              end
              describe "total_rows.i.js" do
                it "directory? should return false" do
                  @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name/total_rows.i.js").should be_false
                end
                it "file? should return true" do
                  @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name/total_rows.i.js").should be_true
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_view/view_function_name/total_rows.i.js").should be_false
                end
              end
              describe "rows/" do
                it "directory? should return true" do
                  @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows").should be_true
                end
                it "file? should return false" do
                  @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows").should be_false
                end
                it "contents should list view rows" do
                  @quilt.contents("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows").should == ["000"]
                end
                it "can_mkdir? should return false" do
                  @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows").should be_false
                end
                it "can_rmdir? should return false" do
                  @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows").should be_false
                end
                describe "000/" do
                  it "directory? should return true" do
                    @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000").should be_true
                  end
                  it "file? should return false" do
                    @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000").should be_false
                  end
                  it "contents should list view result row content" do
                    @quilt.contents("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000").should == ["id.js", "key.js", "value.js"]
                  end
                  it "can_mkdir? should return false" do
                    @quilt.can_mkdir?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000").should be_false
                  end
                  it "can_rmdir? should return false" do
                    @quilt.can_rmdir?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000").should be_false
                  end
                  describe "id.js" do
                    it "directory? should return false" do
                      @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/id.js").should be_false
                    end
                    it "file? should return true" do
                      @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/id.js").should be_true
                    end
                    it "read_file should return contents" do
                      @quilt.read_file("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/id.js").should == "document_id"
                    end
                    it "can_write? should return false" do
                      @quilt.can_write?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/id.js").should be_false
                    end
                    it "can_delete? should return false" do
                      @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/id.js").should be_false
                    end
                  end
                  describe "key.js" do
                    it "directory? should return false" do
                      @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/key.js").should be_false
                    end
                    it "file? should return true" do
                      @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/key.js").should be_true
                    end
                    it "read_file should return contents" do
                      @quilt.read_file("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/key.js").should == "This is a name"
                    end
                    it "can_write? should return false" do
                      @quilt.can_write?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/key.js").should be_false
                    end
                    it "can_delete? should return false" do
                      @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/key.js").should be_false
                    end
                  end
                  describe "value.js" do
                    it "directory? should return false" do
                      @quilt.directory?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/value.js").should be_false
                    end
                    it "file? should return true" do
                      @quilt.file?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/value.js").should be_true
                    end
                    it "read_file should return contents" do
                      @quilt.read_file("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/value.js").should == ""
                    end
                    it "can_write? should return false" do
                      @quilt.can_write?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/value.js").should be_false
                    end
                    it "can_delete? should return false" do
                      @quilt.can_delete?("/#{@database_id}/_design/design_document_id/_view/view_function_name/rows/000/value.js").should be_false
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
