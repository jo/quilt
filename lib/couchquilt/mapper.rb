module Couchquilt
  module Mapper
    def to_parts(path = nil)
      return [] unless path
      parts = path.is_a?(Array) ? path.dup : path.split("/")
      parts.map! { |p| key_for p }
    end

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
