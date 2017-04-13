require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "tag_columns/version"

module TagColumns
  extend ::ActiveSupport::Concern

  module ClassMethods
    def tag_columns_sanitize_list(values=[])
      values.select(&:present?).map(&:to_s).uniq.sort
    end

    def tag_columns(*column_names)
      @tag_columns ||= {}

      tag_columns_sanitize_list(column_names).each do |column_name|
        @tag_columns[column_name] ||= false
      end

      @tag_columns.each do |column_name, initialized|
        next if initialized

        column_name_plural = column_name.pluralize
        quoted_column_name = "#{quoted_table_name}.#{connection.quote_column_name column_name}"

        scope :"with_any_#{column_name}",    ->(*tags) { where "#{quoted_column_name} && ARRAY[?]::varchar[]", tag_columns_sanitize_list(tags) }
        scope :"with_all_#{column_name}",    ->(*tags) { where "#{quoted_column_name} @> ARRAY[?]::varchar[]", tag_columns_sanitize_list(tags) }
        scope :"without_any_#{column_name}", ->(*tags) { where.not "#{quoted_column_name} && ARRAY[?]::varchar[]", tag_columns_sanitize_list(tags) }
        scope :"without_all_#{column_name}", ->(*tags) { where.not "#{quoted_column_name} @> ARRAY[?]::varchar[]", tag_columns_sanitize_list(tags) }

        before_validation Proc.new { self[column_name] = self.class.tag_columns_sanitize_list(self[column_name]) }

        define_method :"has_any_#{column_name_plural}?" do |*values|
          values = self.class.tag_columns_sanitize_list(values)
          existing = self[column_name] || []
          (values & existing).present?
        end

        alias_method :"has_#{column_name_plural}?", :"has_any_#{column_name_plural}?"

        define_method :"has_all_#{column_name_plural}?" do |*values|
          values = self.class.tag_columns_sanitize_list(values)
          existing = self[column_name] || []
          (values & existing).size == values.size
        end

        @tag_columns[column_name] = true
      end
    end
  end
end
