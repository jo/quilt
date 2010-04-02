class Array
  include Couchquilt::Mapper

  def at_path(path)
    parts = path.is_a?(Array) ? path.dup : path.split("/")
    parts.map! { |p| key_for p }
    head = parts.shift
    return self if head.nil?
    part = self[head.to_i]
    return part if parts.empty? || !part.respond_to?(:at_path)
    part.at_path(parts)
  end

  def to_fs(named_path = true)
    # using zip for backwards compatibily:
    # in Ruby 1.9 (and 1.8.7) we could simply use
    # each_with_index.map { |k,i| ... }
    named_path ? zip((0..size).to_a).map { |v,i| name_for(i, v) } : self
  end
end
