require File.join(File.dirname(__FILE__), '../spec_helper.rb')

describe Couchquilt::Mapper do
  include Couchquilt::Mapper

  describe "map_json" do
    describe "value mapping" do
      it "should map string value" do
        result = map_json({ "key" => "value" })
        result.should == ["key.js"]
      end

      it "should map integer value" do
        result = map_json({ "key" => 1 })
        result.should == ["key.i.js"]
      end

      it "should map float value" do
        result = map_json({ "key" => 1.1 })
        result.should == ["key.f.js"]
      end

      it "should map false value" do
        result = map_json({ "key" => false })
        result.should == ["key.b.js"]
      end

      it "should map true value" do
        result = map_json({ "key" => true })
        result.should == ["key.b.js"]
      end

      it "should map an array value" do
        result = map_json(["value"])
        result.should == ["0i.js"]
      end

      it "should map hash value" do
        result = map_json({ "key" => {}})
        result.should == ["key"]
      end

      it "should map array value" do
        result = map_json({ "key" => []})
        result.should == ["key"]
      end
    end

    describe "nested mapping" do
      it "should map only keys" do
        result = map_json("key" => { "key" => "value" })
        result.should == ["key"]
      end
    end

    describe "array mapping" do
      it "should map uniq array values" do
        result = map_json(["value1", "value2"])
        result.should == ["0i.js", "1i.js"]
      end

      it "should map equal array values" do
        result = map_json(["value", "value"])
        result.should == ["0i.js", "1i.js"]
      end
    end
  end

  describe "to_json" do
  end
end
