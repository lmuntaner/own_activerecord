require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.to_s.underscore}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method("#{name}") do
      foreign_key = self.send(options.foreign_key)
      model_class = options.model_class
      hash_result = DBConnection.execute(<<-SQL, foreign_key)
        SELECT
          *
        FROM
          #{model_class.table_name}
        WHERE
          #{options.primary_key} = ?
      SQL
      
      model_class.parse_all(hash_result).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)
    define_method("#{name}") do
      model_class = options.model_class
      hash_result = DBConnection.execute(<<-SQL, self.id)
        SELECT
          *
        FROM
          #{model_class.table_name}
        WHERE
          #{options.foreign_key} = ?
      SQL
      
      model_class.parse_all(hash_result)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
