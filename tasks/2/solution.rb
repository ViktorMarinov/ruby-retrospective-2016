class Hash
  def fetch_deep(path)
    fetch_deep_with_cast(path) { |s| s.to_sym }
  end

  def reshape(shape)
    shape.each_with_object({}) do |(k, v), hash|
      hash[k] = (v.is_a? String) ? self.fetch_deep(v) : reshape(v)
    end
  end
end

class Array
  def fetch_deep(path)
    fetch_deep_with_cast(path) { |s| s.to_i }
  end

  def reshape(shape)
    clone.map { |hash| hash.reshape(shape) }
  end
end

def fetch_deep_with_cast(path)
  head = path.partition('.').first
  tail = path.partition('.').last
  if tail.empty?
    self[yield(head)] || self[head]
  else
    self[yield(head)]&.fetch_deep(tail) || self[head]&.fetch_deep(tail)
  end
end