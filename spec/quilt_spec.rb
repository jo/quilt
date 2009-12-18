require File.join(File.dirname(__FILE__), 'spec_helper.rb')

# Note: databases, documents and keys with slashes are not supported by now
require 'rubygems'
require 'couchrest'

describe "Quilt" do
  before do
    @quilt = Quilt.new 
    @database_id = "quilt-test-db"
    @server_name = @quilt.server_name
    CouchRest.delete(File.join(@server_name, @database_id))
    @db = CouchRest.database!(File.join(@server_name, @database_id))

    @document = {
      "_id" => "document_id",
      "name" => "This is a name",
      "integer" => 12,
      "float" => 1.2,
      "object" => { "key" => "this is a value" },
      "array" => ["this is another value"]
    }
    @db.save_doc(@document)

    @design_document = {
      "_id" => "_design/design_document_id",
      "language" => "javascript",
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

  describe "list contents of" do
    describe "/" do
      # /
      it "should list databases" do
        @quilt.contents("/").should include(@database_id)
      end

      describe "database_id /" do
        # /database_id
        it "should list documents" do
          @quilt.contents("/#{@database_id}").should == ["_design", "document_id"]
        end

        describe "_design /" do
          # /database_id/_design
          it "should list design documents" do
            @quilt.contents("/#{@database_id}/_design").should == ["design_document_id"]
          end

          describe "design_document_id /" do
            # /database_id/_design/design_document_id
            it "should list design documents content" do
              @quilt.contents("/#{@database_id}/_design/design_document_id").should == ["_id.js", "_list", "_rev.js", "_show", "language.js", "lists", "shows", "views"]
            end

            describe "_list /" do
              # /database_id/_design/design_document_id/_list
              it "should list list functions" do
                @quilt.contents("/#{@database_id}/_design/design_document_id/_list").should == ["list_function_name"]
              end

              describe "list_function_name /" do
                # /database_id/_design/design_document_id/_list/list_function_name
                it "should list views" do
                  @quilt.contents("/#{@database_id}/_design/design_document_id/_list/list_function_name").should == ["view_function_name.js"]
                end
              end
            end

            describe "_show /" do
              # /database_id/_design/design_document_id/_show
              it "should list show functions" do
                @quilt.contents("/#{@database_id}/_design/design_document_id/_show").should == ["show_function_name"]
              end

              describe "show_function_name /" do
                # /database_id/_design/design_document_id/_show/show_function_name
                it "should list documents" do
                  @quilt.contents("/#{@database_id}/_design/design_document_id/_show/show_function_name").should == ["document_id.js"]
                end
              end
            end
          end
        end

        describe "document_id /" do
          # /database_id/document_id
          it "should list documents content" do
            @quilt.contents("/#{@database_id}/document_id").should == ["_id.js", "_rev.js", "array", "float.f.js", "integer.i.js", "name.js", "object"]
          end

          describe "object /" do
            # /database_id/document_id/object
            it "should list object content" do
              @quilt.contents("/#{@database_id}/document_id/object").should == ["key.js"]
            end
          end

          describe "array /" do
            # /database_id/document_id/array
            it "should list array content" do
              @quilt.contents("/#{@database_id}/document_id/array").should == ["000.js"]
            end
          end
        end
      end
    end
  end

  describe "check for directory? of" do
    describe "/" do
      # /
      it "should return true" do
        @quilt.directory?("/").should be_true
      end

      describe "database_id /" do
        # /database_id
        it "should return true" do
          @quilt.directory?("/#{@database_id}").should be_true
        end

        describe "document_id /" do
          # /database_id/document_id
          it "should return true" do
            @quilt.directory?("/#{@database_id}/document_id").should be_true
          end
        end

        describe "_design /" do
          # /database_id/_design
          it "should return true" do
            @quilt.directory?("/#{@database_id}/_design").should be_true
          end

          describe "design_document_id /" do
            # /database_id/_design/design_document_id
            it "should return true" do
              @quilt.directory?("/#{@database_id}/_design/design_document_id").should be_true
            end

            describe "_list /" do
              # /database_id/_design/design_document_id/_list
              it "should return true" do
                @quilt.directory?("/#{@database_id}/_design/design_document_id/_list").should be_true
              end
            end

            describe "_show /" do
              # /database_id/_design/design_document_id/_show
              it "should return true" do
                @quilt.directory?("/#{@database_id}/_design/design_document_id/_show").should be_true
              end
            end
          end
        end
      end
    end
  end

  describe "check for file? of" do
    describe "/" do
      # /
      it "should return false" do
        @quilt.file?("/").should be_false
      end

      describe "database_id /" do
        # /database_id
        it "should return false" do
          @quilt.file?("/#{@database_id}").should be_false
        end

        describe "document_id /" do
          # /database_id/document_id
          it "should return false" do
            @quilt.file?("/#{@database_id}/document_id").should be_false
          end
        end

        describe "_design /" do
          # /database_id/_design
          it "should return false" do
            @quilt.file?("/#{@database_id}/_design").should be_false
          end

          describe "design_document_id /" do
            # /database_id/_design/design_document_id
            it "should return false" do
              @quilt.file?("/#{@database_id}/_design/design_document_id").should be_false
            end
          end
        end
      end
    end
  end

  describe "read a file at" do
    describe "/" do
      # /
      it "should return nil" do
        @quilt.read_file("/").should be_nil
      end

      describe "database_id /" do
        # /database_id
        it "should return nil" do
          @quilt.read_file("/#{@database_id}").should be_nil
        end

        describe "document_id /" do
          # /database_id/document_id
          it "should return nil" do
            @quilt.read_file("/#{@database_id}/document_id").should be_nil
          end

          describe "_id.js" do
            # /database_id/document_id/_id.js
            it "should return document_id" do
              @quilt.read_file("/#{@database_id}/document_id/_id.js").should == "document_id"
            end
          end
        end

        describe "_design /" do
          # /database_id/_design
          it "should return nil" do
            @quilt.read_file("/#{@database_id}/_design").should be_nil
          end

          describe "design_document_id /" do
            # /database_id/_design/design_document_id
            it "should return nil" do
              @quilt.read_file("/#{@database_id}/_design/design_document_id").should be_nil
            end

            describe "_id.js" do
              # /database_id/_design/design_document_id/_id.js
              it "should return _design/design_document_id" do
                @quilt.read_file("/#{@database_id}/_design/design_document_id/_id.js").should == "_design/design_document_id"
              end
            end
          end
        end
      end
    end
  end

  describe "write to file at" do
    describe "/" do
      describe "database_id /" do
        describe "document_id /" do
          describe "key.js" do
            # /database_id/document_id/key.js
            it "should update document_id" do
              @quilt.write_to("/#{@database_id}/document_id/key.js", "value").should be_true
            end
          end
        end

        describe "_design /" do
          describe "design_document_id /" do
            describe "_id.js" do
              # /database_id/_design/design_document_id/key.js
              it "should update _design/design_document_id" do
                @quilt.write_to("/#{@database_id}/_design/design_document_id/key.js", "value").should be_true
              end
            end
          end
        end
      end
    end
  end
end
