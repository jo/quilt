class Hash
  include Couchquilt::Mapper

  def at_path(path)
    parts = path.is_a?(Array) ? path.dup : path.split("/")
    parts.map! { |p| key_for p }
    head = parts.shift
    return self if head.nil?
    part = self[head]
    return part if parts.empty? || !part.respond_to?(:at_path)
    part.at_path(parts)
  end

  def update_at_path(path, value)
    current = self
    
    parts = path.is_a?(Array) ? path.dup : path.split("/")
    key = parts.pop

    return self unless key

    parts.each do |part|
      current[part] ||= {}
      current = current[part]
      
      raise 'updating value at %s failed!' % inspect unless current.is_a?(self.class)
    end

    current[key] = value
  end

  def to_fs(named_path = true)
    named_path ? keys.map { |k| name_for(k, self[k]) }.sort : keys.sort
  end
end
