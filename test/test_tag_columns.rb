require "pry-test"
require "coveralls"
Coveralls.wear!
SimpleCov.command_name "pry-test"
require_relative "../lib/tag_columns"

class TestTagColumns < PryTest::Test
  test "stub" do
    assert true
  end
end
