module Model
  def attributes(*attributes)
    if attributes.empty?
      @instance_variables
    else
      @instance_variables = attributes << :id

      define_methods
    end
  end

  def data_store(data_store = nil)
    if data_store
      @data_store = data_store
    else
      @data_store
    end
  end

  def instance_variables
    @instance_variables || []
  end

  def where(query)
    query.keys.each do |attr|
      unless instance_variables.include? attr
        raise DataModel::UnknownAttributeError, "Unknown attribute #{attr}"
      end
    end

    data_store.find(query).map { |model| self.new(model) }
  end

  private

  def define_methods
    instance_variables.each do |var|
      define_singleton_method "find_by_#{var}" do |arg|
        where({var => arg})
      end

      define_method(var) { @object[var] }
      define_method("#{var}=") { |value| @object[var] = value }
    end
  end
end

class DataModel
  extend Model

  class DeleteUnsavedRecordError < StandardError
  end

  class UnknownAttributeError < StandardError
  end

  def initialize(initial_values = {})
    @object = initial_values.select do |key, _| 
      self.class.instance_variables.include? key
    end
  end

  def save
    if id
      self.class.data_store.update(id, @object)
    else
      self.id = self.class.data_store.next_id
      self.class.data_store.create(@object)
    end

    self
  end

  def delete
    if id
      self.class.data_store.delete(id: id)
    else
      raise DeleteUnsavedRecordError
    end
  end

  def ==(other)
    return false if self.class != other.class

    return id == other.id if id && other.id

    equal? other
  end
end

class ArrayStore
  attr_reader :storage

  def initialize
    @storage = []
    @id_counter = 0
  end

  def next_id
    @id_counter += 1
  end

  def create(record)
    @storage << record
  end

  def find(query)
    @storage.select { |record| match_record? query, record } 
  end

  def update(id, attributes)
    index = @storage.find_index { |record| match_record?({id: id}, record) }
    raise ArgumentError, "No record with id: #{id} " unless index
  
    attributes.each { |key, value| @storage[index][key] = value }
  end

  def delete(query)
    @storage.reject! { |record| match_record? query, record }
  end

  private 

  def match_record?(query, record)
    query.all? { |key, value| record[key] == value }
  end
end

class HashStore
  attr_reader :storage

  def initialize
    @storage = {}
    @id_counter = 0
  end

  def next_id
    @id_counter += 1
  end

  def create(record)
    id = record[:id]
    @storage[id] = record
  end

  def update(id, attributes)
    raise ArgumentError, "No record with id: #{id} " unless @storage.key? id
    
    attributes.each { |key, value| @storage[id][key] = value }
  end

  def find(query)
    @storage.values.select do |record|
      query.all? { |key, value| record[key] == value }
    end
  end

  def delete(query)
    find(query).each { |record| @storage.delete(record[:id]) }
  end
end