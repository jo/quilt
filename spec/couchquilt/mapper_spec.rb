require File.join(File.dirname(__FILE__), '../spec_helper.rb')

describe Couchquilt::Mapper do
  include Couchquilt::Mapper

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
