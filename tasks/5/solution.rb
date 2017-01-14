module Model
  def attributes(*attributes)
    if attributes != []
      attr_accessor *attributes
      @instance_variables = attributes.dup
      @instance_variables.unshift :id
      create_find_by_methods
    else
      @instance_variables
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

  def inherited(_)
    attr_accessor :id
  end

  private

  def create_find_by_methods
    instance_variables.each do |var| 
      define_singleton_method "find_by_#{var}" do |arg|
        where({var => arg})
      end
    end
  end
end

module Serializable
  private
  def to_hash
    hash = {}
    instance_variables.each do |var|
      hash[var[1..-1].to_sym] = instance_variable_get(var)
    end
    hash
  end

  def from_hash(**attributes)
    instance_variables = self.class.instance_variables
    instance_variables.each do |var|
      i_var = "@#{var}"
      instance_variable_set i_var, attributes[var]
    end
  end
end

module Saveable
  def save
    unless @id
      @id = self.class.data_store.id_counter
      self.class.data_store.id_counter += 1
    end
    self.class.data_store.create(to_hash)
    self
  end

  def saved?
    @id != nil
  end
end

class DataModel
  extend Model
  include Serializable
  include Saveable

  class DeleteUnsavedRecordError < StandardError
  end

  class UnknownAttributeError < StandardError
  end

  class << self
    def where(**attributes)
      attributes.keys.each do |attr|
        unless instance_variables.include? attr 
          raise UnknownAttributeError, "Unknown attribute #{attr}"
        end
      end
      data_store.find(**attributes).map { |model| self.new(model) }
    end
  end

  def initialize(**initial_values)
    from_hash(**initial_values)
  end

  def delete
    if saved?
      self.class.data_store.delete(id: @id)
    else
      raise DeleteUnsavedRecordError
    end
  end

  def ==(other)
    if self.class == other.class
      if self.saved? && other.saved?
        self.id == other.id
      else
        self.equal? other
      end
    else
      false
    end
  end
end

class DataStore
  attr_accessor :storage, :id_counter

  def initialize
    @id_counter = 1
  end

  def create(record)
    id = record[:id]
    add(record) if id_available? id 
  end

  def update(id, **attributes)
    found_records = find(id: id)
    raise ArgumentError, "No record with id: #{id} " if found_records.empty?
    
    record = found_records[0]
    attributes.each { |key, value| record[key] = value }
  end

  def find(**query)
    records.select do |record| 
      query.each.all? { |key, value| record[key] == value }
    end
  end

  private

  def id_available?(id)
    !(records.map { |record| record[:id] }.include? id)
  end
end

class ArrayStore < DataStore
  def initialize
    @storage = []
    super
  end

  def delete(**query)
    found_records = find(**query)
    storage.delete_if { |record| found_records.include? record }
  end

  private

  def records
    @storage
  end

  def add(record)
    storage.push(record)
  end
end

class HashStore < DataStore
  def initialize
    @storage = {}
    super
  end

  def add(record)
    storage[record[:id]] = record
  end

  def delete(**query)
    found_records = find(**query)
    storage.delete_if { |_key, value| found_records.include? value }
  end

  private
  
  def records
    @storage.values
  end
end