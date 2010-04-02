require File.join(File.dirname(__FILE__), '../spec_helper.rb')

# Note: databases, documents and keys with slashes are not supported by now
describe Couchquilt::FS do
  before :all do
    RestClient.put(File.join(SERVER_NAME, TESTDB), nil)

    @document = {
      "_id" => "document_id",
      "name" => "This is a name",
      "integer" => 12,
      "float" => 1.2,
      "boolean" => true,
      "object" => { "key" => "this is a value" },
      "array" => ["this is another value"],
      "empty" => {}
    }
    RestClient.put File.join(SERVER_NAME, TESTDB, @document["_id"]), @document.to_json

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
    RestClient.put File.join(SERVER_NAME, TESTDB, @design_document["_id"]), @design_document.to_json

    @quilt = Couchquilt::DebuggedFS.new("http://127.0.0.1:5984")
  end

  after :all do
    RestClient.delete(File.join(SERVER_NAME, TESTDB))
  end

  # /
  describe "/" do
    before do
      @path = "/"
    end

    it "directory? should return true" do
      @quilt.directory?(@path).should be_true
    end
    it "file? should return false" do
      @quilt.file?(@path).should be_false
    end
    it "contents should list databases" do
      @quilt.contents(@path).should include(TESTDB)
    end
    it "contents should include _uuids" do
      @quilt.contents(@path).should include("_uuids")
    end
    it "can_mkdir? should return false" do
      @quilt.can_mkdir?(@path).should be_false
    end
    it "can_rmdir? should return false" do
      @quilt.can_rmdir?(@path).should be_false
    end

    # /unknown_database
    describe "unknown_database/" do
      before do
        @path = "/unknown_database"
      end

      it "directory? should return false" do
        @quilt.directory?(@path).should be_false
      end
      it "file? should return false" do
        @quilt.file?(@path).should be_false
      end
      it "can_mkdir? should return true" do
        @quilt.can_mkdir?(@path).should be_true
      end
    end

    # /new_database
    describe "#{TESTDB}-new/" do
      before do
        @path = "/#{TESTDB}-new"
      end

      it "mkdir should create database which touch _delete should remove" do
        @quilt.directory?(@path).should be_false
        @quilt.mkdir(@path).should be_true
        @quilt.directory?(@path).should be_true
        @quilt.touch("#{@path}/_delete").should be_true
        @quilt.directory?(@path).should be_false
      end
    end

    # /database_id
    describe "database_id/" do
      before do
        @path = "/#{TESTDB}"
      end

      it "directory? should return true" do
        @quilt.directory?(@path).should be_true
      end
      it "file? should return false" do
        @quilt.file?(@path).should be_false
      end
      it "contents should list documents" do
        @quilt.contents(@path).should == ["_design", "compact_running.b.js", "db_name.js", "disk_format_version.i.js", "disk_size.i.js", "doc_count.i.js", "doc_del_count.i.js", "document_id", "instance_start_time.js", "purge_seq.i.js", "update_seq.i.js"]
      end
      it "can_mkdir? should return false" do
        @quilt.can_mkdir?(@path).should be_false
      end
      it "can_rmdir? should return false" do
        @quilt.can_rmdir?(@path).should be_false
      end

      # /database_id/db_name.js
      describe "db_name.js" do
        before do
          @path = "/#{TESTDB}/db_name.js"
        end

        it "directory? should return false" do
          @quilt.directory?(@path).should be_false
        end
        it "file? should return true" do
          @quilt.file?(@path).should be_true
        end
        it "read_file should return contents" do
          @quilt.read_file(@path).should == TESTDB
        end
        it "can_write? should return false" do
          @quilt.can_write?(@path).should be_false
        end
        it "can_delete? should return false" do
          @quilt.can_delete?(@path).should be_false
        end
      end

      # /database_id/doc_count.i.js
      describe "doc_count.i.js" do
        before do
          @path = "/#{TESTDB}/doc_count.i.js"
        end

        it "directory? should return false" do
          @quilt.directory?(@path).should be_false
        end
        it "file? should return true" do
          @quilt.file?(@path).should be_true
        end
        it "read_file should return contents" do
          @quilt.read_file(@path).should == "2"
        end
        it "can_write? should return false" do
          @quilt.can_write?(@path).should be_false
        end
        it "can_delete? should return false" do
          @quilt.can_delete?(@path).should be_false
        end
      end

      # /database_id/unknown_document
      describe "unknown_document/" do
        before do
          @path = "/#{TESTDB}/unknown_document"
        end

        it "directory? should return false" do
          @quilt.directory?(@path).should be_false
        end
        it "file? should return false" do
          @quilt.file?(@path).should be_false
        end
        it "can_mkdir? should return true" do
          @quilt.can_mkdir?(@path).should be_true
        end
        it "can_rmdir? should return false" do
          @quilt.can_rmdir?(@path).should be_false
        end
      end

      # /database_id/document_id
      describe "document_id/" do
        before do
          @path = "/#{TESTDB}/document_id"
        end

        it "directory? should return true" do
          @quilt.directory?(@path).should be_true
        end
        it "file? should return false" do
          @quilt.file?(@path).should be_false
        end
        it "contents should list documents content" do
          @quilt.contents(@path).should == ["_id.js", "_rev.js", "array", "boolean.b.js", "empty", "float.f.js", "integer.i.js", "name.js", "object"]
        end
        it "can_mkdir? should return false" do
          @quilt.can_mkdir?(@path).should be_false
        end
        it "can_rmdir? should return false" do
          @quilt.can_rmdir?(@path).should be_false
        end
        it "touch _delete should delete document" do
          @quilt.touch("#{@path}/_delete").should be_true
          @quilt.directory?(@path).should be_false
        end
        
        # /database_id/document_id/unknown_attribute
        describe "unknown_attribute/" do
          before do
            @path = "/#{TESTDB}/document_id/unknown_attribute"
          end

          it "directory? should return false" do
            @quilt.directory?(@path).should be_false
          end
          it "file? should return false" do
            @quilt.file?(@path).should be_false
          end
          it "can_mkdir? should return true" do
            @quilt.can_mkdir?(@path).should be_true
          end
          it "mkdir should update document while rmdir should reset it" do
            @quilt.mkdir(@path).should be_true
            @quilt.directory?(@path).should be_true
            @quilt.rmdir(@path).should be_true
            @quilt.directory?(@path).should be_false
          end
        end

        # /database_id/document_id/_id.js
        describe "_id.js" do
          before do
            @path = "/#{TESTDB}/document_id/_id.js"
          end

          it "directory? should return false" do
            @quilt.directory?(@path).should be_false
          end
          it "file? should return true" do
            @quilt.file?(@path).should be_true
          end
          it "read_file should return contents" do
            @quilt.read_file(@path).should == "document_id"
          end
          it "can_write? should return false" do
            @quilt.can_write?(@path).should be_false
          end
          it "can_delete? should return false" do
            @quilt.can_delete?(@path).should be_false
          end
        end

        # /database_id/document_id/name.js
        describe "name.js" do
          before do
            @path = "/#{TESTDB}/document_id/name.js"
          end

          it "directory? should return false" do
            @quilt.directory?(@path).should be_false
          end
          it "file? should return true" do
            @quilt.file?(@path).should be_true
          end
          it "read_file should return contents" do
            @quilt.read_file(@path).should == @document["name"]
          end
          it "can_write? should return true" do
            @quilt.can_write?(@path).should be_true
          end
          it "write_to should update document" do
            @quilt.write_to(@path, "value").should be_true
          end
          it "can_delete? should return false" do
            @quilt.can_delete?(@path).should be_true
          end
          it "delete should update document" do
            @quilt.delete(@path).should be_true
            @quilt.file?(@path).should be_false
          end
        end

        # /database_id/document_id/boolean.b.js
        describe "boolean.b.js" do
          before do
            @path = "/#{TESTDB}/document_id/boolean.b.js"
          end

          it "directory? should return false" do
            @quilt.directory?(@path).should be_false
          end
          it "file? should return true" do
            @quilt.file?(@path).should be_true
          end
          it "read_file should return contents" do
            @quilt.read_file(@path).should == @document["boolean"].to_s
          end
          it "can_write? should return true" do
            @quilt.can_write?(@path).should be_true
          end
          it "write_to should update document" do
            @quilt.write_to(@path, "value").should be_true
          end
          it "can_delete? should return true" do
            @quilt.can_delete?(@path).should be_true
          end
          it "delete should update document" do
            @quilt.delete(@path).should be_true
            @quilt.file?(@path).should be_false
          end
        end

        # /database_id/document_id/object
        describe "object/" do
          before do
            @path = "/#{TESTDB}/document_id/object"
          end

          it "directory? should return true" do
            @quilt.directory?(@path).should be_true
          end
          it "file? should return false" do
            @quilt.file?(@path).should be_false
          end
          it "contents should list object content" do
            @quilt.contents(@path).should == ["key.js"]
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?(@path).should be_false
          end
          it "can_rmdir? should return false when not empty" do
            @quilt.can_rmdir?(@path).should be_false
          end
        end
        
        # /database_id/document_id/array
        describe "array/" do
          before do
            @path = "/#{TESTDB}/document_id/array"
          end

          it "directory? should return true" do
            @quilt.directory?(@path).should be_true
          end
          it "file? should return false" do
            @quilt.file?(@path).should be_false
          end
          it "contents should list array content" do
            @quilt.contents(@path).should == ["0i.js"]
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?(@path).should be_false
          end
          it "can_rmdir? should return false when not empty" do
            @quilt.can_rmdir?(@path).should be_false
          end

          # /database_id/document_id/array/0i.js
          describe "0i.js" do
            before do
              @path = "/#{TESTDB}/document_id/array/0i.js"
            end

            it "directory? should return false" do
              @quilt.directory?(@path).should be_false
            end
            it "file? should return true" do
              @quilt.file?(@path).should be_true
            end
            it "read_file should return contents" do
              @quilt.read_file(@path).should == @document["array"].first
            end
            it "can_write? should return true" do
              @quilt.can_write?(@path).should be_true
            end
            it "write_to should update document" do
              @quilt.write_to(@path, "value").should be_true
            end
            it "can_delete? should return true" do
              @quilt.can_delete?(@path).should be_true
            end
            it "delete should update document" do
              @quilt.delete(@path).should be_true
              @quilt.file?(@path).should be_false
            end
          end
        end
        
        # /database_id/document_id/empty
        describe "empty/" do
          before do
            @path = "/#{TESTDB}/document_id/empty"
          end

          it "directory? should return true" do
            @quilt.directory?(@path).should be_true
          end
          it "file? should return false" do
            @quilt.file?(@path).should be_false
          end
          it "contents should list empty content" do
            @quilt.contents(@path).should == []
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?(@path).should be_false
          end
          it "can_rmdir? should return true when empty" do
            @quilt.can_rmdir?(@path).should be_true
          end
          it "rmdir should remove empty from document tree when empty" do
            @quilt.rmdir(@path).should be_true
            @quilt.directory?(@path).should be_false
          end
        end
      end
      
      # /database_id/_design
      describe "_design/" do
        before do
          @path = "/#{TESTDB}/_design"
        end

        it "directory? should return true" do
          @quilt.directory?(@path).should be_true
        end
        it "file? should return false" do
          @quilt.file?(@path).should be_false
        end
        it "contents should list design documents" do
          @quilt.contents(@path).should == ["design_document_id"]
        end
        it "can_mkdir? should return false" do
          @quilt.can_mkdir?(@path).should be_false
        end
        it "can_rmdir? should return false" do
          @quilt.can_rmdir?(@path).should be_false
        end

        # /database_id/_design/new_design_document_id
        describe "new_design_document_id/" do
          before do
            @path = "/#{TESTDB}/_design/new_design_document_id"
          end

          it "mkdir should create design document which touch _delete should remove" do
            @quilt.directory?(@path).should be_false
            @quilt.mkdir(@path).should be_true
            @quilt.directory?(@path).should be_true
            @quilt.touch("#{@path}/_delete").should be_true
            @quilt.directory?(@path).should be_false
          end
        end
        
        # /database_id/_design/design_document_id
        describe "design_document_id/" do
          before do
            @path = "/#{TESTDB}/_design/design_document_id"
          end

          it "directory? should return true" do
            @quilt.directory?(@path).should be_true
          end
          it "file? should return false" do
            @quilt.file?(@path).should be_false
          end
          it "contents should list design documents content" do
            @quilt.contents(@path).should == ["_id.js", "_list", "_rev.js", "_show", "_view", "language.js", "lists", "name.js", "shows", "views"]
          end
          it "can_mkdir? should return false" do
            @quilt.can_mkdir?(@path).should be_false
          end
          it "can_rmdir? should return false" do
            @quilt.can_rmdir?(@path).should be_false
          end
          
          # /database_id/_design/design_document_id/_id.js
          describe "_id.js" do
            before do
              @path = "/#{TESTDB}/_design/design_document_id/_id.js"
            end

            it "directory? should return false" do
              @quilt.directory?(@path).should be_false
            end
            it "file? should return true" do
              @quilt.file?(@path).should be_true
            end
            it "read_file should return value" do
              @quilt.read_file(@path).should == @design_document["_id"]
            end
            it "can_write? should return false" do
              @quilt.can_write?(@path).should be_false
            end
            it "can_delete? should return false" do
              @quilt.can_delete?(@path).should be_false
            end
          end
          
          # /database_id/_design/design_document_id/name.js
          describe "name.js" do
            before do
              @path = "/#{TESTDB}/_design/design_document_id/name.js"
            end

            it "directory? should return false" do
              @quilt.directory?(@path).should be_false
            end
            it "file? should return true" do
              @quilt.file?(@path).should be_true
            end
            it "read_file should return value" do
              @quilt.read_file(@path).should == @design_document["name"]
            end
            it "can_write? should return true" do
              @quilt.can_write?(@path).should be_true
            end
            it "write_to should update _design/design_document_id" do
              @quilt.write_to(@path, "value").should be_true
            end
            it "can_delete? should return true" do
              @quilt.can_delete?(@path).should be_true
            end
            it "delete should update design document" do
              @quilt.delete(@path).should be_true
              @quilt.file?(@path).should be_false
            end
          end
          
          # /database_id/_design/design_document_id/_list
          describe "_list/" do
            before do
              @path = "/#{TESTDB}/_design/design_document_id/_list"
            end

            it "directory? should return true" do
              @quilt.directory?(@path).should be_true
            end
            it "file? should return false" do
              @quilt.file?(@path).should be_false
            end
            it "contents should list list functions" do
              @quilt.contents(@path).should == ["list_function_name"]
            end
            it "can_mkdir? should return false" do
              @quilt.can_mkdir?(@path).should be_false
            end
            it "can_rmdir? should return false" do
              @quilt.can_rmdir?(@path).should be_false
            end
            
            # /database_id/_design/design_document_id/_list/list_function_name
            describe "list_function_name/" do
              before do
                @path = "/#{TESTDB}/_design/design_document_id/_list/list_function_name"
              end

              it "directory? should return true" do
                @quilt.directory?(@path).should be_true
              end
              it "file? should return false" do
                @quilt.file?(@path).should be_false
              end
              it "contents should list views" do
                @quilt.contents(@path).should == ["view_function_name.html"]
              end
              it "can_mkdir? should return false" do
                @quilt.can_mkdir?(@path).should be_false
              end
              it "can_rmdir? should return false" do
                @quilt.can_rmdir?(@path).should be_false
              end
              
              # /database_id/_design/design_document_id/_list/list_function_name/view_function_name.html
              describe "view_function_name.html" do
                before do
                  @path = "/#{TESTDB}/_design/design_document_id/_list/list_function_name/view_function_name.html"
                end

                it "directory? should return false" do
                  @quilt.directory?(@path).should be_false
                end
                it "file? should return true" do
                  @quilt.file?(@path).should be_true
                end
                it "read_file should return contents" do
                  @quilt.read_file(@path).should == "Hello World!"
                end
                it "can_write? should return false" do
                  @quilt.can_write?(@path).should be_false
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?(@path).should be_false
                end
              end
            end
          end
          
          # /database_id/_design/design_document_id/_show
          describe "_show/" do
            before do
              @path = "/#{TESTDB}/_design/design_document_id/_show"
            end

            it "directory? should return true" do
              @quilt.directory?(@path).should be_true
            end
            it "file? should return false" do
              @quilt.file?(@path).should be_false
            end
            it "contents should list show functions" do
              @quilt.contents(@path).should == ["show_function_name"]
            end
            it "can_mkdir? should return false" do
              @quilt.can_mkdir?(@path).should be_false
            end
            it "can_rmdir? should return false" do
              @quilt.can_rmdir?(@path).should be_false
            end
            
            # /database_id/_design/design_document_id/_show/show_function_name
            describe "show_function_name/" do
              before do
                @path = "/#{TESTDB}/_design/design_document_id/_show/show_function_name"
              end

              it "directory? should return true" do
                @quilt.directory?(@path).should be_true
              end
              it "file? should return false" do
                @quilt.file?(@path).should be_false
              end
              it "contents should list documents" do
                @quilt.contents(@path).should == ["document_id.html"]
              end
              it "can_mkdir? should return false" do
                @quilt.can_mkdir?(@path).should be_false
              end
              it "can_rmdir? should return false" do
                @quilt.can_rmdir?(@path).should be_false
              end
              
              # /database_id/_design/design_document_id/_show/show_function_name/document_id.html
              describe "document_id.html" do
                before do
                  @path = "/#{TESTDB}/_design/design_document_id/_show/show_function_name/document_id.html"
                end

                it "directory? should return false" do
                  @quilt.directory?(@path).should be_false
                end
                it "file? should return true" do
                  @quilt.file?(@path).should be_true
                end
                it "read_file should return contents" do
                  @quilt.read_file(@path).should == "Hello World!"
                end
                it "can_write? should return false" do
                  @quilt.can_write?(@path).should be_false
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?(@path).should be_false
                end
              end
            end
          end
          
          # /database_id/_design/design_document_id/_view
          describe "_view/" do
            before do
              @path = "/#{TESTDB}/_design/design_document_id/_view"
            end

            it "directory? should return true" do
              @quilt.directory?(@path).should be_true
            end
            it "file? should return false" do
              @quilt.file?(@path).should be_false
            end
            it "contents should list view functions" do
              @quilt.contents(@path).should == ["view_function_name"]
            end
            it "can_mkdir? should return false" do
              @quilt.can_mkdir?(@path).should be_false
            end
            it "can_rmdir? should return false" do
              @quilt.can_rmdir?(@path).should be_false
            end
            
            # /database_id/_design/design_document_id/_view/view_function_name
            describe "view_function_name/" do
              before do
                @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name"
              end

              it "directory? should return true" do
                @quilt.directory?(@path).should be_true
              end
              it "file? should return false" do
                @quilt.file?(@path).should be_false
              end
              it "contents should list view result document contents" do
                @quilt.contents(@path).should == ["offset.i.js", "rows", "total_rows.i.js"]
              end
              it "can_mkdir? should return false" do
                @quilt.can_mkdir?(@path).should be_false
              end
              it "can_rmdir? should return false" do
                @quilt.can_rmdir?(@path).should be_false
              end

              # /database_id/_design/design_document_id/_view/view_function_name/offset.i.js
              describe "offset.i.js" do
                before do
                  @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name/offset.i.js"
                end

                it "directory? should return false" do
                  @quilt.directory?(@path).should be_false
                end
                it "file? should return true" do
                  @quilt.file?(@path).should be_true
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?(@path).should be_false
                end
              end

              # /database_id/_design/design_document_id/_view/view_function_name/total_rows.i.js
              describe "total_rows.i.js" do
                before do
                  @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name/total_rows.i.js"
                end

                it "directory? should return false" do
                  @quilt.directory?(@path).should be_false
                end
                it "file? should return true" do
                  @quilt.file?(@path).should be_true
                end
                it "can_delete? should return false" do
                  @quilt.can_delete?(@path).should be_false
                end
              end

              # /database_id/_design/design_document_id/_view/view_function_name/rows
              describe "rows/" do
                before do
                  @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name/rows"
                end

                it "directory? should return true" do
                  @quilt.directory?(@path).should be_true
                end
                it "file? should return false" do
                  @quilt.file?(@path).should be_false
                end
                it "contents should list view rows" do
                  @quilt.contents(@path).should == ["0i"]
                end
                it "can_mkdir? should return false" do
                  @quilt.can_mkdir?(@path).should be_false
                end
                it "can_rmdir? should return false" do
                  @quilt.can_rmdir?(@path).should be_false
                end

                # /database_id/_design/design_document_id/_view/view_function_name/rows/0i
                describe "0i/" do
                  before do
                    @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name/rows/0i"
                  end

                  it "directory? should return true" do
                    @quilt.directory?(@path).should be_true
                  end
                  it "file? should return false" do
                    @quilt.file?(@path).should be_false
                  end
                  it "contents should list view result row content" do
                    @quilt.contents(@path).should == ["id.js", "key.js", "value.js"]
                  end
                  it "can_mkdir? should return false" do
                    @quilt.can_mkdir?(@path).should be_false
                  end
                  it "can_rmdir? should return false" do
                    @quilt.can_rmdir?(@path).should be_false
                  end

                  # /database_id/_design/design_document_id/_view/view_function_name/rows/0i/id.js
                  describe "id.js" do
                    before do
                      @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name/rows/0i/id.js"
                    end

                    it "directory? should return false" do
                      @quilt.directory?(@path).should be_false
                    end
                    it "file? should return true" do
                      @quilt.file?(@path).should be_true
                    end
                    it "read_file should return contents" do
                      @quilt.read_file(@path).should == "document_id"
                    end
                    it "can_write? should return false" do
                      @quilt.can_write?(@path).should be_false
                    end
                    it "can_delete? should return false" do
                      @quilt.can_delete?(@path).should be_false
                    end
                  end

                  # /database_id/_design/design_document_id/_view/view_function_name/rows/0i/key.js
                  describe "key.js" do
                    before do
                      @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name/rows/0i/key.js"
                    end

                    it "directory? should return false" do
                      @quilt.directory?(@path).should be_false
                    end
                    it "file? should return true" do
                      @quilt.file?(@path).should be_true
                    end
                    it "read_file should return contents" do
                      @quilt.read_file(@path).should == "This is a name"
                    end
                    it "can_write? should return false" do
                      @quilt.can_write?(@path).should be_false
                    end
                    it "can_delete? should return false" do
                      @quilt.can_delete?(@path).should be_false
                    end
                  end

                  # /database_id/_design/design_document_id/_view/view_function_name/rows/0i/value.js
                  describe "value.js" do
                    before do
                      @path = "/#{TESTDB}/_design/design_document_id/_view/view_function_name/rows/0i/value.js"
                    end

                    it "directory? should return false" do
                      @quilt.directory?(@path).should be_false
                    end
                    it "file? should return true" do
                      @quilt.file?(@path).should be_true
                    end
                    it "read_file should return contents" do
                      @quilt.read_file(@path).should == ""
                    end
                    it "can_write? should return false" do
                      @quilt.can_write?(@path).should be_false
                    end
                    it "can_delete? should return false" do
                      @quilt.can_delete?(@path).should be_false
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    # /_uuids
    describe "_uuids/" do
      before do
        @path = "/_uuids"
      end

      it "directory? should return true" do
        @quilt.directory?(@path).should be_true
      end
      it "file? should return false" do
        @quilt.file?(@path).should be_false
      end
      it "can_mkdir? should return false" do
        @quilt.can_mkdir?(@path).should be_false
      end
      it "can_rmdir? should return false" do
        @quilt.can_rmdir?(@path).should be_false
      end
      it "contents should include 0i.js" do
        @quilt.contents(@path).should == ["0i.js"]
      end

      # /_uuids/0i.js
      describe "0i.js" do
        before do
          @path = "/_uuids/0i.js"
        end

        it "directory? should return false" do
          @quilt.directory?(@path).should be_false
        end
        it "file? should return true" do
          @quilt.file?(@path).should be_true
        end
        it "can_delete? should return false" do
          @quilt.can_delete?(@path).should be_false
        end
        it "can_write? should return false" do
          @quilt.can_write?(@path).should be_false
        end
        it "read_file should return contents" do
          @quilt.read_file(@path).should =~ /\A[a-z0-9]{32}\z/
        end
      end
    end
  end
end
