module Couchquilt
  module Mapper
    # maps json contents into contents array
    def map_json(json = {})
      case json
      when Hash
        json.keys.sort.map { |k| fs_name_for(k, json[k]) }
      when Array
        # using zip for backwards compatibily:
        # in Ruby 1.9 (and 1.8.7) we could simply use
        # json.each_with_index.map { |k,i| ... }
        json.zip((0..json.size).to_a).map { |v,i| fs_name_for(i, v) }
      end
    end

    def to_json(array = [])
    end

    private

    # Appends extname, that is: builds a filename from key and value.
    # Note: values are casted by extension.
    def fs_name_for(key, value)
      basename = key.is_a?(Integer) ? "%di" % key : key
  
      case value
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
