# TagColumns

Fast & simple Rails ActiveRecord model tagging using [PostgreSQL's](https://www.postgresql.org/) [Array datatype](https://www.postgresql.org/docs/current/static/arrays.html).

*Similar to [acts_as_taggable_on](https://github.com/mbleigh/acts-as-taggable-on) but lighter weight with fewer features.*

## Use Cases

Assign categories to your database records.

* Assign multiple groups to user records
* Assign categories to blog posts et al.
* etc...

## Quick Start

```ruby
# Gemfile
gem "tag_columns"
```

```ruby
# db/migrate/TIMESTAMP_add_groups_to_user.rb
class AddGroupsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :groups, :string, array: true, default: "{}", null: false
    add_index :users, :groups, using: "gin"
  end
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include TagColumns
  tag_columns :groups
end
```

```ruby
user = User.find(1)

# assigning tags
user.groups << :reader
user.groups << :writer
user.save

# checking tags
is_writer            = user.has_group?(:writer)
is_reader_or_writer  = user.has_any_groups?(:reader, :writer)
is_reader_and_writer = user.has_all_groups?(:reader, :writer)

# finding tagged records
writers                 = User.with_any_groups(:writer)
non_writers             = User.without_any_groups(:writer)
readers_or_writers      = User.with_any_groups(:reader, :writer)
readers_and_writers     = User.with_all_groups(:reader, :writer)
non_readers_and_writers = User.without_all_groups(:reader, :writer)
```
