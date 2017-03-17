require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  attr_reader :table_name, :attributes, :columns

  def self.columns
    query = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      LIMIT
        0
    SQL
    @columns ||= DBConnection.execute2(query).first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=") { |val| attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    query = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    self.parse_all(query)
  end

  def self.parse_all(results)
    results.map do |row_hash|
      self.new(row_hash)
    end
  end

  def self.find(id)
    rows = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    rows == [] ? nil : self.new(rows[0])
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", value)
    end

  end

  def table
    self.class.table_name
  end

  def columns
    self.class.columns
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    attr_keys = attributes.keys.join(", ")
    question_marks = (["?"] * (attribute_values.length)).join(", ")
    new_row = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{table} (#{attr_keys})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id

  end

  def update
    set_line = attributes.keys.map { |c| "#{c} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{table}
      SET
        #{set_line}
      WHERE
        id = #{self.id}
    SQL

  end

  def save
    attributes[:id].nil? ? insert : update
  end
end
