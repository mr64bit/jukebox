module AjaxDatatablesRailsTableHelper
  class TableManager
    attr_reader :tables

    def initialize(table_defs)
      @tables = table_defs.each_with_object([]){|table, array| array << Table.new(table[:role], table[:primary_model], table[:columns])}
    end

    def table_for(role)
      @tables.find{|table| table.role == role}
    end

    class Table
      attr_reader :role, :columns
      def initialize(role, model, columns)
        @role = role
        @columns = columns
      end

      def headers
        @columns.each_with_object(""){|column, string| string << "<th>#{column[:header_name]}</th>" }
      end

      def sortable
        @columns.select{|col| col[:orderable].class != FalseClass}.map{|col| col[:db_column]}
      end

      def searchable
        @columns.select{|col| col[:searchable].class != FalseClass}.map{|col| col[:db_column]}
      end

      def record_columns(record)
        @columns.map{|col| col[:source].call(record)}
      end

      def javascript_columns
        string = '['
        size = columns.size
        columns.each_with_index{|col, i| string << "#{javascript_column(col)}#{i >= size - 1 ? '' : ','}"}
        string + ']'
      end

      private

      def javascript_column(column)
        string = { orderable: column[:orderable].class != FalseClass, searchable: column[:searchable].class != FalseClass }.to_json
        string.insert(1, "#{column[:javascript]},") if column[:javascript]
        string
      end
    end
  end
end
