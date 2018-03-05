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

        method_name = column_name.downcase
        quoted_column_name = "#{quoted_table_name}.#{connection.quote_column_name column_name}"

        define_singleton_method :"unique_#{method_name}" do |conditions='true'|
          result = connection.execute <<~QUERY
            SELECT DISTINCT unnest(#{quoted_column_name}) AS unique_#{method_name}
            FROM #{quoted_table_name}
            WHERE #{where(conditions).to_sql.split(/ WHERE /i).last}
            AND #{quoted_column_name} IS NOT NULL
            AND #{quoted_column_name} != '{}'
            ORDER BY unique_#{method_name}
          QUERY
          result.values.flatten
        end

        scope :"with_#{method_name}",        -> { where("#{quoted_column_name}::text[] IS NOT NULL").where("#{quoted_column_name}::text[] != '{}'") }
        scope :"without_#{method_name}",     -> { where("#{quoted_column_name}::text[] IS NULL").or where("#{quoted_column_name}::text[] = '{}'") }
        scope :"with_any_#{method_name}",    ->(*tags) { where "#{quoted_column_name}::text[] && ARRAY[?]::text[]", tag_columns_sanitize_list(tags) }
        scope :"with_all_#{method_name}",    ->(*tags) { where "#{quoted_column_name}::text[] @> ARRAY[?]::text[]", tag_columns_sanitize_list(tags) }
        scope :"without_any_#{method_name}", ->(*tags) { where.not "#{quoted_column_name}::text[] && ARRAY[?]::text[]", tag_columns_sanitize_list(tags) }
        scope :"without_all_#{method_name}", ->(*tags) { where.not "#{quoted_column_name}::text[] @> ARRAY[?]::text[]", tag_columns_sanitize_list(tags) }

        before_validation Proc.new { self[column_name] = self.class.tag_columns_sanitize_list(self[column_name]) }

        define_method :"has_any_#{method_name}?" do |*values|
          values = self.class.tag_columns_sanitize_list(values)
          existing = self.class.tag_columns_sanitize_list(self[column_name] || [])
          (values & existing).present?
        end

        define_method :"has_all_#{method_name}?" do |*values|
          values = self.class.tag_columns_sanitize_list(values)
          existing = self.class.tag_columns_sanitize_list(self[column_name] || [])
          (values & existing).size == values.size
       end

        alias_method :"has_#{method_name.singularize}?", :"has_all_#{method_name}?"

        @tag_columns[column_name] = true
      end
    end
  end
end
