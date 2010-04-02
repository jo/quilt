module Couchquilt
  module Mapper
    # recursively updates a part of a json hash from fs
    # TODO: remove
    def map_fs(json, keys = [], value = :empty)
      return {} if keys.empty?

      insert_as_array = keys.last =~ /.+\.array\Z/
      key = key_for(keys.shift)
      if keys.empty?
        if value.nil? && json.is_a?(Hash)
          json.delete key
        elsif value.nil? && json.is_a?(Array)
          json.delete_at key
        elsif value == :empty && insert_as_array
          json[key] = []
        elsif value == :empty
          json[key] = {}
        else
          json[key] = value
        end
      else
        json[key] = map_fs(json[key], keys, value)
      end

      json
    end

    private

    # remove fs mapping extnames
    # and converts array entry mappings
    def key_for(name)
      return name unless name.is_a?(String)
      if name =~ /\A\d+i(\.js)?\z/
        name.to_i
      else
        name.sub(/((\.(f|i|b))?\.js|\.html|\.array)\z/, "")
      end
    end

    # Appends extname, that is: builds a filename from key and value.
    # Note: values are casted by extension.
    def name_for(key, value = nil)
      basename = key.is_a?(Integer) ? "%di" % key : key.to_s

      case value
      when Array
        "#{basename}.array"
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
  end
end
