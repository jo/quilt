require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Hash and Array" do
  describe "at_path" do
    it "should retrieve top level" do
      hash = { "a" => 1 }
      hash.at_path("/").should == hash
    end

    it "should retrieve value at top level" do
      hash = { "a" => 1 }
      hash.at_path("a").should == 1
    end

    it "should retrieve value at nested level" do
      hash = { "a" => { "b" => 1 } }
      hash.at_path("a/b").should == 1
    end

    it "should retrieve value at deep nested level" do
      hash = { "a" => { "b" => { "c" => 1 } } }
      hash.at_path("a/b/c").should == 1
    end

    it "should return nil if not present" do
      hash = { "a" => { "c" => { "c" => 1 } } }
      hash.at_path("a/b/c").should == nil
    end

    it "should return part of an array" do
      hash = { "a" => [1] }
      hash.at_path("a/0i").should == 1
    end

    it "should return part of a nested array" do
      hash = { "a" => [ { "b" => 1 } ] }
      hash.at_path("a/0i/b").should == 1
    end
  end

  describe "update_at_path" do
    it "should insert value at top level" do
      hash = { }
      hash.update_at_path "a", 1
      hash.should == { "a" => 1 }
    end

    it "should insert value at nested level" do
      hash = { }
      hash.update_at_path "a/b", 1
      hash.should == { "a" => { "b" => 1 } }
    end

    it "should insert value at deep nested level" do
      hash = { }
      hash.update_at_path "a/b/c", 1
      hash.should == { "a" => { "b" => { "c" => 1 } } }
    end
  end

  describe "to_fs" do
    it "should map string value" do
      hash = { "key" => "value" }
      hash.to_fs.should == ["key.js"]
    end

    it "should map integer value" do
      hash = { "key" => 1 }
      hash.to_fs.should == ["key.i.js"]
    end

    it "should map float value" do
      hash = { "key" => 1.1 }
      hash.to_fs.should == ["key.f.js"]
    end

    it "should map false value" do
      hash = { "key" => false }
      hash.to_fs.should == ["key.b.js"]
    end

    it "should map true value" do
      hash = { "key" => true }
      hash.to_fs.should == ["key.b.js"]
    end

    it "should map hash value" do
      hash = { "key" => {}}
      hash.to_fs.should == ["key"]
    end

    it "should map array value" do
      hash = { "key" => []}
      hash.to_fs.should == ["key.array"]
    end
  end
end
