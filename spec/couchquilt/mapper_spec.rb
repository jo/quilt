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
        result.should == ["key.array"]
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

  describe "map_fs" do
    before do
      @json = { "a" => 1, "b" => { "ab" => 1 }}
    end

    it "should remove all contents for empty keys" do
      result = map_fs(@json)
      result.should == {}
    end
    
    it "should update a" do
      result = map_fs(@json, ["a"], 2)
      result.should == @json.merge("a" => 2)
    end

    it "should insert c" do
      result = map_fs(@json, ["c"], 1)
      result.should == @json.merge("c" => 1)
    end

    it "should update nested ab" do
      result = map_fs(@json, ["b", "ab"], 2)
      result.should == @json.merge("b" => { "ab" => 2 })
    end

    it "should insert nested ac" do
      result = map_fs(@json, ["b", "ac"], 1)
      result.should == @json.merge("b" => { "ab" => 1, "ac" => 1 })
    end
  end

  describe "key_for" do
    it "should return parsed integer value for 1i" do
      result = key_for("1i")
      result.should == 1
    end

    it "should return parsed integer value for 1i.js" do
      result = key_for("1i.js")
      result.should == 1
    end

    it "should remove js extension" do
      result = key_for("key.js")
      result.should == "key"
    end

    it "should remove f.js extension" do
      result = key_for("key.f.js")
      result.should == "key"
    end

    it "should remove i.js extension" do
      result = key_for("key.i.js")
      result.should == "key"
    end

    it "should remove b.js extension" do
      result = key_for("key.b.js")
      result.should == "key"
    end

    it "should remove html extension" do
      result = key_for("key.html")
      result.should == "key"
    end
  end

  describe "name_for" do
    describe "with integer key" do
      it "should append i.js for nil value" do
        result = name_for(1)
        result.should == "1i.js"
      end

      it "should append i.js for string value" do
        result = name_for(1, "value")
        result.should == "1i.js"
      end

      it "should append i.f.js for float value" do
        result = name_for(1, 1.1)
        result.should == "1i.f.js"
      end

      it "should append i.i.js for integer value" do
        result = name_for(1, 1)
        result.should == "1i.i.js"
      end

      it "should append i.b.js for true value" do
        result = name_for(1, true)
        result.should == "1i.b.js"
      end

      it "should append i.b.js for false value" do
        result = name_for(1, false)
        result.should == "1i.b.js"
      end
    end

    describe "with other key" do
      it "should append js for nil value" do
        result = name_for("key")
        result.should == "key.js"
      end

      it "should append js for string value" do
        result = name_for("key", "value")
        result.should == "key.js"
      end

      it "should append f.js for float value" do
        result = name_for("key", 1.1)
        result.should == "key.f.js"
      end

      it "should append i.js for integer value" do
        result = name_for("key", 1)
        result.should == "key.i.js"
      end

      it "should append b.js for true value" do
        result = name_for("key", true)
        result.should == "key.b.js"
      end

      it "should append b.js for false value" do
        result = name_for("key", false)
        result.should == "key.b.js"
      end
    end
  end
end
