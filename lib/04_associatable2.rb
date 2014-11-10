require_relative '03_associatable'

# Phase IV
module Associatable

  def has_one_through(name, through_name, source_name)
    define_method("#{name}") do
      ### Using one single query
      through_options = self.class.assoc_options[through_name]
      model_class_through = through_options.model_class
      source_options = model_class_through.assoc_options[source_name]
      model_class_source = source_options.model_class
      source_table = model_class_source.table_name
      through_table = model_class_through.table_name
      through_fk = source_options.foreign_key
      through_pk = source_options.primary_key
      fk_value = self.send(through_options.foreign_key)
      hash_results = DBConnection.execute(<<-SQL, fk_value)
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
      
      ### Using our own #where method
      # # Data to get to the through object
      # through_options = self.class.assoc_options[through_name]
      # model_class_through = through_options.model_class
      # fk_value_through = self.send(through_options.foreign_key)
      #
      # # Human.where(id: ?) -> ? = owner_id of cat
      # params_through = {through_options.primary_key => fk_value_through}
      # object_through = model_class_through.where(params_through).first
      #
      # # Data to get to the source object
      # source_options = model_class_through.assoc_options[source_name]
      # model_class_source = source_options.model_class
      # fk_value = object_through.send(source_options.foreign_key)
      #
      # # House.where(id: ?) -> ? = home_id of human with id = owner_id
      # params = {source_options.primary_key => fk_value}
      # model_class_source.where(params).first
      
      ### Using belongs_to
      # object_through = self.send(through_name)
      # object_through.send(source_name)
    end
  end
  
  def has_many_through(name, through_name, source_name)
    define_method("#{name}") do
      ### Using has_many
      # objects_through = self.send(through_name)
      # objects_source = []
      # objects_through.each do |object_through|
      #   objects_source += object_through.send(source_name)
      # end
      # objects_source
      
      ### Using one single query
      through_options = self.class.assoc_options[through_name]
      model_class_through = through_options.model_class
      source_options = model_class_through.assoc_options[source_name]
      model_class_source = source_options.model_class
      source_table = model_class_source.table_name
      through_table = model_class_through.table_name
      through_fk = source_options.foreign_key
      through_pk = source_options.primary_key
      hash_results = DBConnection.execute(<<-SQL, self.id)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{through_pk} = #{source_table}.#{through_fk}
        WHERE
          #{through_table}.#{through_options.foreign_key} = ?
      SQL
      
      model_class_source.parse_all(hash_results)
    end
  end
end
