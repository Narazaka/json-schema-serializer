# Json::Schema::Serializer

[![Actions Status](https://github.com/Narazaka/json-schema-serializer/workflows/Ruby/badge.svg)](https://github.com/Narazaka/json-schema-serializer/actions)
[![Gem Version](https://badge.fury.io/rb/json-schema-serializer.svg)](https://badge.fury.io/rb/json-schema-serializer)

JSON Schema based serializer

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json-schema-serializer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json-schema-serializer

## Usage

```ruby
require "json/schema/serializer"

schema = {
  type: "object",
  properties: {
    id: { type: "integer" },
    name: { type: "string" },
    fuzzy: { type: ["string", "integer", "null"] },
  },
  required: ["id"],
}

serializer = JSON::Schema::Serializer.new(schema)

serializer.serialize({id: "42", name: "me", foo: "bar", fuzzy: "1000"})
# => {"id"=>42, "name"=>"me", "fuzzy"=>"1000"}
# "42" -> 42! type coerced!

serializer.serialize({id: "42", name: "me", fuzzy: 42})
# => {"id"=>42, "name"=>"me", "fuzzy"=>42}
serializer.serialize({id: "42", name: "me"})
# => {"id"=>42, "name"=>"me", "fuzzy"=>nil}
# multiple type auto select!

serializer.serialize({})
# => {"id"=>0, "name"=>nil, "fuzzy"=>nil}
# nil -> 0! required property's type coerced!

serializer.serialize({id: 10, name: "I don't need null keys!"}).compact
# => {"id"=>10, "name"=>"I don't need null keys!"}
# compact it!

class A
  def id
    42
  end
end
serializer.serialize(A.new)
# => {"id"=>42, "name"=>nil, "fuzzy"=>nil}
# method also allowed

class Schema
  def type
    :string
  end
end
serializer2 = JSON::Schema::Serializer.new(Schema.new)
serializer2.serialize(32)
# => "32"
# non-hash schema allowed

#
# object injector allowed!
#

class FooSerializer
  def initialize(model)
    @model = model
  end

  def first
    @model.first
  end

  def count
    @model.size
  end
end

serializer_injected = JSON::Schema::Serializer.new(
  {
    type: :object,
    inject: :Foo,
    properties: {
      first: { type: :integer },
      count: { type: :integer },
    },
  },
  {
    inject_key: :inject,
    injectors: {
      Foo: FooSerializer,
    },
  },
)

serializer_injected.serialize([1, 2, 3])
# => {"first"=>1, "count"=>3}
```

### Caution

`JSON::Schema::Serializer` does not resolve `$ref` so use external resolver.

with `json_refs` gem example:

```ruby
require "json_refs"
require "json/schema/serializer"


schema = {
  "type" => "object",
  "properties" => {
    "foo" => { "type" => "integer" },
    "bar" => { "$ref" => "#/properties/foo" },
  },
}

serializer = JSON::Schema::Serializer.new(JsonRefs.(schema))
serializer.serialize({foo: 0, bar: "42"})
# => {"foo"=>0, "bar"=>42}
```

## License

Zlib License

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Narazaka/json-schema-serializer.
