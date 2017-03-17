require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    param_values = params.values
    param_keys = params.keys.map do |k|
      "#{k} = ?"
    end.join(" AND ")
    results = DBConnection.execute(<<-SQL, param_values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{param_keys}
    SQL
    if results == []
      return []
    else
      results.map do |results_hash|
        self.new(results_hash)
      end
    end 
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
