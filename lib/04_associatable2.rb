require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method("#{name}") do
      through_options = self.class.assoc_options[through_name]
      model_class_through = through_options.model_class
      source_options = model_class_through.assoc_options[source_name]
      model_class_source = source_options.model_class
      source_table = model_class_source.table_name
      through_table = model_class_through.table_name
      through_fk = source_options.foreign_key
      through_pk = source_options.primary_key
      foreign_key = self.send(through_options.foreign_key)
      hash_results = DBConnection.execute(<<-SQL, foreign_key)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{through_fk} = #{source_table}.#{through_pk}
        WHERE
          #{through_table}.#{through_options.primary_key} = ?
      SQL
      
      model_class_source.new(hash_results.first)
    end
  end
  
  def has_many_through(name, through_name, source_name)
  end
end
