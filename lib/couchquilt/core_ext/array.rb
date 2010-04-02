class Array
  include Couchquilt::Mapper

  def at_path(path)
    head, *parts = to_parts(path)
    return self if head.nil?
    head = head.to_i
    part = self[head]
    return part if parts.empty? || !part.respond_to?(:at_path)
    part.at_path(parts)
  end

  def update_at_path(path, value)
    head, *parts = to_parts(path)
    return if head.nil?
    head = head.to_i
    return self[head] = value if parts.empty?
    self[head] ||= []
    self[head].update_at_path(parts, value)
  end

  def delete_at_path(path)
    head, *parts = to_parts(path)
    return if head.nil?
    head = head.to_i
    return self.delete_at(head) if parts.empty?
    return unless self[head]
    self[head].delete_at_path(parts)
  end

  def to_fs(named_path = true)
    # using zip for backwards compatibily:
    # in Ruby 1.9 (and 1.8.7) we could simply use
    # each_with_index.map { |k,i| ... }
    named_path ? zip((0..size).to_a).map { |v,i| name_for(i, v) } : self
  end
end
