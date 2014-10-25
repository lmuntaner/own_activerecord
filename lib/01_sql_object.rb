require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  
  def self.columns
    @columns ||= (DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
      SQL
      .first.map(&:to_sym))
  end

  def self.finalize!
    columns.each do |attribute|
      define_method("#{attribute}=") do |value|
        attributes[attribute] = value
      end
      define_method("#{attribute}") do
        attributes[attribute]
      end
    end
  end

  #this method will allow us to set a table name instance variable
  def self.table_name=(table_name)
    @table_name = table_name
  end

  #this one will either use the table name set above, OR figure it out from class name
  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    hash_results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    
    parse_all(hash_results)
  end

  def self.parse_all(results)
    objects = []
    results.each do |params|
      objects << self.new(params)
    end
    
    objects
  end

  def self.find(id)
    hash_result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    
    parse_all(hash_result).first
  end

  def initialize(params = {})
    attr_names = self.class.columns
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless attr_names.include?(attr_sym)
      getter = "#{attr_name}=".to_sym
      self.send(getter, value)
    end
    
    
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attr_values = []
    self.class.columns.each do |attr_name|
      attr_values << self.send(attr_name)
    end
    
    attr_values
  end

  def insert
    values = attribute_values[1..-1]
    col_names = self.class.columns.select { |attr_name| attr_name != :id}.join(" ,")
    question_marks = (["?"] * values.count).join(" ,")
    DBConnection.execute(<<-SQL, *values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    values = attribute_values[1..-1] + [attribute_values[0]]
    attr_names = self.class.columns.select { |attr_name| attr_name != :id}
    col_names = attr_names.map do |attr_name|
      "#{attr_name} = ?"
    end.join(" ,")
    question_marks = (["?"] * values.count).join(", ")
    DBConnection.execute(<<-SQL, *values)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
