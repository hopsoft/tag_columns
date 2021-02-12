require "pry-test"
require "coveralls"
Coveralls.wear!
SimpleCov.command_name "pry-test"
require_relative "../lib/tag_columns"

class TagColumnsTester
  include TagColumns
end

class TestTagColumns < PryTest::Test
  include TagColumns

  test "tag_columns_sanitize_list with no arg" do
    assert TagColumnsTester.tag_columns_sanitize_list == []
  end

  test "tag_columns_sanitize_list with empty list arg" do
    assert TagColumnsTester.tag_columns_sanitize_list([]) == []
  end

  test "tag_columns_sanitize_list with nil arg" do
    assert TagColumnsTester.tag_columns_sanitize_list(nil) == []
  end

  test "tag_columns_sanitize_list with upper case list" do
    assert TagColumnsTester.tag_columns_sanitize_list(%w[C B A]) == %w[A B C]
  end

  test "tag_columns_sanitize_list with lower case list" do
    assert TagColumnsTester.tag_columns_sanitize_list(%w[c b a]) == %w[a b c]
  end
end
