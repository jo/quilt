require File.join(File.dirname(__FILE__), 'spec_helper.rb')

# Note: databases, documents and keys with slashes are not supported by now
describe "Quilt" do
  before do
    @quilt = Quilt.new 
  end

  describe "contents" do
    describe "/" do
      it "should list databases" do
        @quilt.db.should_receive("databases").and_return(["database"])
        @quilt.contents("/").should == ["database"]
      end

      describe "database" do
        it "should list documents" do
          @quilt.db.should_receive("documents").with('database').and_return(["document"])
          @quilt.contents("/database").should == ["document"]
        end

        describe "_design" do
          it "should list design documents" do
            @quilt.db.should_receive("design_documents").with('database').and_return(["design_document"])
            @quilt.contents("/database/_design").should == ["design_document"]
          end

          describe "document" do
            it "should list design documents content" do
              @quilt.db.should_receive("get_document").with('database', '_design/document').and_return("_id" => "_design/document")
              @quilt.contents("/database/_design/document").should == ["_id.js"]
            end
          end
        end

        describe "document" do
          it "should list documents content" do
            @quilt.db.should_receive("get_document").with('database', 'document').and_return("_id" => "document")
            @quilt.contents("/database/document").should == ["_id.js"]
          end

          describe "object" do
            it "should list object content" do
              @quilt.db.should_receive("get_document").with('database', 'document').and_return("object" => { "key" => "value" })
              @quilt.contents("/database/document/object").should == ["key.js"]
            end
          end

          describe "array" do
            it "should list array content" do
              @quilt.db.should_receive("get_document").with('database', 'document').and_return("array" => ["value"])
              @quilt.contents("/database/document/array").should == ["000.js"]
            end
          end
        end
      end
    end
  end

  describe "directory?" do
    describe "/" do
      it "should return true" do
        @quilt.directory?("/").should be_true
      end

      describe "database" do
        it "should return true" do
          @quilt.db.should_receive("database?").with('database').and_return(true)
          @quilt.directory?("/database").should be_true
        end

        describe "document" do
          it "should return true" do
            @quilt.db.should_receive("get_document").with('database', 'document').and_return({})
            @quilt.directory?("/database/document").should be_true
          end
        end

        describe "_design" do
          it "should return true" do
            @quilt.directory?("/database/_design").should be_true
          end

          describe "document" do
            it "should return true" do
              @quilt.db.should_receive("get_document").with('database', '_design/document').and_return({})
              @quilt.directory?("/database/_design/document").should be_true
            end
          end
        end
      end
    end
  end

  describe "file?" do
    describe "/" do
      it "should return false" do
        @quilt.file?("/").should be_false
      end

      describe "database" do
        it "should return false" do
          @quilt.file?("/database").should be_false
        end

        describe "document" do
          it "should return false" do
            @quilt.file?("/database/document").should be_false
          end
        end

        describe "_design" do
          it "should return false" do
            @quilt.file?("/database/_design").should be_false
          end

          describe "document" do
            it "should return false" do
              @quilt.file?("/database/_design/document").should be_false
            end
          end
        end
      end
    end
  end

  describe "read_file" do
    describe "/" do
      it "should return nil" do
        @quilt.read_file("/").should be_nil
      end

      describe "database" do
        it "should return nil" do
          @quilt.read_file("/database").should be_nil
        end

        describe "document" do
          it "should return nil" do
            @quilt.read_file("/database/document").should be_nil
          end

          describe "_id.js" do
            it "should return document" do
              @quilt.db.should_receive("get_document").with('database', 'document').and_return("_id" => "document")
              @quilt.read_file("/database/document/_id.js").should == "document"
            end
          end
        end

        describe "_design" do
          it "should return nil" do
            @quilt.read_file("/database/_design").should be_nil
          end

          describe "document" do
            it "should return nil" do
              @quilt.read_file("/database/_design/document").should be_nil
            end

            describe "_id.js" do
              it "should return _design/document" do
                @quilt.db.should_receive("get_document").with('database', '_design/document').and_return("_id" => "_design/document")
                @quilt.read_file("/database/_design/document/_id.js").should == "_design/document"
              end
            end
          end
        end
      end
    end
  end

  describe "write_to" do
    describe "/" do
      describe "database" do
        describe "document" do
          describe "key.js" do
            it "should update document" do
              doc = { "_id" => "document" }
              @quilt.db.should_receive("get_document").with('database', "document").and_return(doc)
              @quilt.db.should_receive("save_document").with('database', doc.update("key" => "value")).and_return(true)
              @quilt.write_to("/database/document/key.js", "value").should be_true
            end
          end
        end

        describe "_design" do
          describe "document" do
            describe "_id.js" do
              it "should update _design/document" do
                doc = { "_id" => "_design/document" }
                @quilt.db.should_receive("get_document").with('database', "_design/document").and_return(doc)
                @quilt.db.should_receive("save_document").with('database', doc.update("key" => "value")).and_return(true)
                @quilt.write_to("/database/_design/document/key.js", "value").should be_true
              end
            end
          end
        end
      end
    end
  end
end
