require File.join(File.dirname(__FILE__), 'test_helper.rb')
# Sample data:
#
# document
#   {
#     "array": [
#       "value",
#       ["value"],
#       { "key": "value" }
#     ],
#     "decimal": 0.5,
#     "number": 1,
#     "object": {
#       "key": "value",
#       "object": { "key": "value" },
#       ["value"]
#     },
#     "string": "value",
#     "empty_array": [],
#     "empty_object": []
#   }
#
# document/
#   array/
#     000.js            # value
#     001/
#       000.js            # value
#     002/
#       key.js            # value
#   decimal.float       # 0.5
#   number.integer      # 1
#   object/
#     array/
#       000.js            # value
#     key               # value
#     object/
#       key.js            # value
#   string.js           # value
#   empty_array/
#   empty_object/
#
class JsonFsTest < Test::Unit::TestCase
  def setup
    @hash = {
      "array" => [
        "value",
        ["value"],
        { "key" => "value" },
      ],
      "float" => 0.5,
      "integer" => 1,
      "hash" => {
        "key" => "value",
        "hash" => { "key" => "value" },
        "array" => ["value"],
      },
      "string" => "value",
      "empty_array" => [],
  #    "empty_object" => {},  currently not supported.
    }
  end

  def test_to_json
    sampledir = File.join(File.dirname(__FILE__), "sample/document")
    assert_equal @hash, JsonFS.to_json(sampledir)
  end

  def test_to_fs
    sampledir = File.join(File.dirname(__FILE__), "sample/document")
    newdir = File.join(File.dirname(__FILE__), "sample/document_copy")
    `rm #{newdir} -rf`
    assert JsonFS.to_fs(newdir, @hash)
    assert_equal_fs sampledir, newdir
  ensure
    `rm #{newdir} -rf`
  end

  def assert_equal_fs(source, target)
    entries = Dir.glob(File.join(source, "*"))
    entries.each do |file|
      target_file = File.join(target, File.basename(file))
      if File.directory?(file)
        assert_equal_fs(file, target_file)
      else
        assert File.file?(target_file), "%s not present" % target_file
        assert_equal File.read(file), File.read(target_file), "%s has different content than %s" % [target_file, file]
      end
    end
  end
end
