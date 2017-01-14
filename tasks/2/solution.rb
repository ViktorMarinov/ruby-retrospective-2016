class Hash
  def fetch_deep(path)
    head, tail = path.split('.', 2)
    value = self[head.to_sym] || self[head.to_s]

    return value unless tail

    value&.fetch_deep(tail)
  end

  def reshape(shape)
    shape.map do |k, v|
      [k, (v.is_a? String) ? self.fetch_deep(v) : reshape(v)]
    end.to_h
  end
end

class Array
  def fetch_deep(path)
    head, tail = path.split('.', 2)
    element = self[head.to_i]

    element.fetch_deep(tail) if element
  end

  def reshape(shape)
    map { |hash| hash.reshape(shape) }
  end
end