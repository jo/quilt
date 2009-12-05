class JsonFS
  class << self
    # returns a json representation of the filesystem under path
    def to_json(path)
      return unless File.directory?(path)
      entries = Dir.glob(File.join(path, "*"))
      json = entries.all? { |e| File.basename(e) =~ /\A\d+(\.(i|f|js))?\z/ } ? [] : {}
      entries.sort.each do |file|
        key, value = read_file(file)
        if json.is_a?(Hash)
          json[key] = value
        elsif json.is_a?(Array)
          json << value
        end
      end
      json
    end

    # writes json data to filesystem at path
    def to_fs(path, json)
      return unless File.directory?(File.dirname(path))
      Dir.mkdir(path) unless File.directory?(path)
      if json.is_a?(Hash)
        json.each do |key, value|
          file = File.join(path, key)
          if value.is_a?(Hash) || value.is_a?(Array)
            Dir.mkdir(file)
            to_fs file, value
          else
            write_file(file, json[key])
          end
        end
      elsif json.is_a?(Array)
        json.each_with_index do |value, key|
          file = File.join(path, "%.3d" % key)
          if value.is_a?(Hash) || value.is_a?(Array)
            Dir.mkdir(file)
            to_fs file, value
          else
            write_file(file, json[key])
          end
        end
      else
        write_file(path, json)
      end
      true
    end

    private

    # reads a file from filesystem
    # returns an array of name and content:
    # [name, content]
    def read_file(file)
      name = File.basename(file)
      if File.directory?(file)
        [name, to_json(file)]
      elsif File.file?(file)
        str = File.read(file)
        str.strip!
        case file
        when /\.f\z/
          [name[0..-3], str.to_f]
        when /\.i\z/
          [name[0..-3], str.to_i]
        when /\.js\z/
          [name[0..-4], str]
        else
          [name, str]
        end
      end
    end

    # writes a file
    def write_file(path, json)
      case json
      when Float
        filename = "#{path}.f"
      when Integer
        filename = "#{path}.i"
      else
        filename = "#{path}.js"
      end
      File.open(filename, "w") { |f| f << json.to_s << "\n" }
    end
  end
end
