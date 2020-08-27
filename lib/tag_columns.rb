require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "tag_columns/version"

module TagColumns
  extend ActiveSupport::Concern

  module ClassMethods
    def tag_columns_sanitize_list(values = [])
      values.select(&:present?).map(&:to_s).uniq.sort
    end

    def tag_columns(*column_names)
      @tag_columns ||= {}

      tag_columns_sanitize_list(column_names).each do |column_name|
        @tag_columns[column_name] ||= false
      end

      @tag_columns.each do |column_name, initialized|
        next if initialized

        column_name = column_name.to_s
        method_name = column_name.downcase

        define_singleton_method :"unique_#{method_name}" do |conditions = "true"|
          unnest = Arel::Nodes::NamedFunction.new("unnest", [arel_table[column_name]])
          query = distinct.select(unnest)
            .where(conditions)
            .where.not(arel_table[column_name].eq(nil))
            .where.not(arel_table[column_name].eq("{}"))
          connection.execute(query.to_sql).values.flatten.sort
        end

        define_singleton_method :"#{method_name}_cloud" do |conditions = "true"|
          unnest = Arel::Nodes::NamedFunction.new("unnest", [arel_table[column_name]])
          query = unscoped.select(unnest.as("tag"))
            .where(conditions)
            .where.not(arel_table[column_name].eq(nil))
            .where.not(arel_table[column_name].eq("{}"))
          from(query).group("tag").order("tag").pluck(Arel.sql("tag, count(*) as count"))
        end

        scope :"with_#{method_name}", -> {
          where.not(arel_table[column_name].eq(nil)).where.not(arel_table[column_name].eq("{}"))
        }

        scope :"without_#{method_name}", -> {
          where(arel_table[column_name].eq(nil)).or(where(arel_table[column_name].eq("{}")))
        }

        scope :"with_any_#{method_name}", ->(*tags) {
          column_cast = Arel::Nodes::NamedFunction.new("CAST", [arel_table[column_name].as("text[]")])
          value = Arel::Nodes::SqlLiteral.new(sanitize_sql_array(["ARRAY[?]", tag_columns_sanitize_list(tags)]))
          value_cast = Arel::Nodes::NamedFunction.new("CAST", [value.as("text[]")])
          overlap = Arel::Nodes::InfixOperation.new("&&", column_cast, value_cast)
          where overlap
        }

        scope :"with_all_#{method_name}", ->(*tags) {
          column_cast = Arel::Nodes::NamedFunction.new("CAST", [arel_table[column_name].as("text[]")])
          value = Arel::Nodes::SqlLiteral.new(sanitize_sql_array(["ARRAY[?]", tag_columns_sanitize_list(tags)]))
          value_cast = Arel::Nodes::NamedFunction.new("CAST", [value.as("text[]")])
          contains = Arel::Nodes::InfixOperation.new("@>", column_cast, value_cast)
          where contains
        }

        scope :"without_any_#{method_name}", ->(*tags) {
          column_cast = Arel::Nodes::NamedFunction.new("CAST", [arel_table[column_name].as("text[]")])
          value = Arel::Nodes::SqlLiteral.new(sanitize_sql_array(["ARRAY[?]", tag_columns_sanitize_list(tags)]))
          value_cast = Arel::Nodes::NamedFunction.new("CAST", [value.as("text[]")])
          overlap = Arel::Nodes::InfixOperation.new("&&", column_cast, value_cast)
          where.not overlap
        }

        scope :"without_all_#{method_name}", ->(*tags) {
          column_cast = Arel::Nodes::NamedFunction.new("CAST", [arel_table[column_name].as("text[]")])
          value = Arel::Nodes::SqlLiteral.new(sanitize_sql_array(["ARRAY[?]", tag_columns_sanitize_list(tags)]))
          value_cast = Arel::Nodes::NamedFunction.new("CAST", [value.as("text[]")])
          contains = Arel::Nodes::InfixOperation.new("@>", column_cast, value_cast)
          where.not contains
        }

        before_validation -> { self[column_name] = self.class.tag_columns_sanitize_list(self[column_name]) }

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
