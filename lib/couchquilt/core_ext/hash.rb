class Hash
  include Couchquilt::Mapper

  def at_path(path)
    head, *parts = to_parts(path)
    return self if head.nil?
    part = self[head]
    return part if parts.empty? || !part.respond_to?(:at_path)
    part.at_path(parts)
  end

  def update_at_path(path, value)
    head, *parts = to_parts(path)
    return if head.nil?
    return self[head] = value if parts.empty?
    self[head] ||= {}
    self[head].update_at_path(parts, value)
  end

  def delete_at_path(path)
    head, *parts = to_parts(path)
    return if head.nil?
    return self.delete(head) if parts.empty?
    return unless self[head]
    self[head].delete_at_path(parts)
  end

  def to_fs(named_path = true)
    named_path ? keys.map { |k| name_for(k, self[k]) }.sort : keys.sort
  end

  def map_arrays!
    each do |key, value|
      next unless value.is_a?(Hash)
      if value.keys.all? { |k| k =~ /^\d+$/ }
        self[key] = value.keys.sort.map { |k| value[k] }
      else
        value.map_arrays!
      end
    end
    self
  end
end
