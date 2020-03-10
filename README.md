# JSON::Schema::Serializer

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

#
# object injector with context
#

class BarSerializer
  def initialize(model, context = nil)
    @model = model
    @context = context
  end

  def id
    @model[:id]
  end

  def score
    @context[@model[:id]]
  end
end

inject_context = {
  1 => 100,
  2 => 200,
}

serializer_injected_with_context = JSON::Schema::Serializer.new(
  {
    type: :object,
    inject: :Bar,
    properties: {
      id: { type: :integer },
      score: { type: :integer },
    },
  },
  {
    inject_key: :inject,
    injectors: {
      Bar: BarSerializer,
    },
    inject_context: inject_context,
  },
)

serializer_injected_with_context.serialize({ id: 1 })
# => { "id" => 1, "score" => 100 }
```

### "additionalProperties"

"additionalProperties" is allowed but must be a schema object or `false`. (not `true`)

If "additionalProperties" does not exists, this serializer works as `{ additionalProperties": false }`.

### `$ref` resolving

`JSON::Schema::Serializer` does not resolve `$ref` so use external resolver.

with `hana` and `json_refs` gem example:

```ruby
require "hana"
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

# resolver option also available

def walk(all, part)
  if part.is_a?(Array)
    part.map { |item| walk(all, item) }
  elsif part.is_a?(Hash)
    ref = part["$ref"] || part[:"$ref"]
    if ref
      Hana::Pointer.new(ref[1..-1]).eval(all)
    else
      part.map { |k, v| [k, walk(all, v)] }.to_h
    end
  else
    part
  end
end

serializer2 = JSON::Schema::Serializer.new(schema["properties"]["bar"], {
  resolver: ->(part_schema) do
    walk(JsonRefs.(schema), part_schema))
  end
})
```

## JSON::Schema::Serializer API

### .new(schema, options = nil)

The initializer.

#### schema [any]

JSON schema object. The serializer tries schema["type"], schema[:type] and schema.type!

#### options [Hash]

options

#### options[:resolver] [Proc]

schema object `$ref` resolver

#### options[:schema_key_transform_for_input] [Proc]

input key transform

```ruby
new({
  type: :object,
  properties: {
    userCount: { type: :integer },
  },
}, { schema_key_transform_for_input: ->(name) { name.underscore } }).serialize({ user_count: 1 }) == { "userCount" => 1 }
```

#### options[:schema_key_transform_for_output] [Proc]

output key transform

```ruby
new({
  type: :object,
  properties: {
    userCount: { type: :integer },
  },
}, { schema_key_transform_for_output: ->(name) { name.underscore } }).serialize({ userCount: 1 }) == { "user_count" => 1 }
```

#### options[:injectors] [Hashlike<String, Class>, Class], options[:inject_key] [String, Symbol], options[:inject_context] [any]

If schema has inject key, the serializer treats data by `injectors[inject_key].new(data)` (or `injectors.send(inject_key).new(data)`).

And if `inject_context` is present, `injectors[inject_key].new(data, inject_context)` (or `injectors.send(inject_key).new(data, inject_context)`).

See examples in [Usage](#usage).

CAUTION: In many case you should define the `nil?` method in the injector class because Injector always initialized by `Injector.new(obj)` even if obj == nil.

#### options[:null_through] [Boolean]

If data is null, always serialize null.

```ruby
new({ type: :string }, { null_through: true }).serialize(nil) == nil
```

#### options[:empty_string_number_coerce_null] [Boolean]

If data == "" in integer or number schema, returns nil.

```ruby
new({ type: :integer }, { empty_string_number_coerce_null: true }).serialize("") == nil
```

#### options[:empty_string_boolean_coerce_null] [Boolean]

If data == "" in boolean schema, returns nil.

```ruby
new({ type: :boolean }, { empty_string_boolean_coerce_null: true }).serialize("") == nil
```

#### options[:false_values] [Enumerable]

If specified, boolean schema treats `!false_values.include?(data)`.

```ruby
new({ type: :boolean }, { false_values: Set.new([false]) }).serialize(nil) == true
```

#### options[:no_boolean_coerce] [Boolean]

If true, boolean schema treats only `true` to be `true`.

```ruby
new({ type: :boolean }, { no_boolean_coerce: true }).serialize(1) == false
```

#### options[:guard_primitive_in_structure] [Boolean]

If true, array or object schema does not accept primitive data and returns empty value.


```ruby
new({ type: :object }, { guard_primitive_in_structure: true }).serialize(1) == {}
new({ type: :object }, { guard_primitive_in_structure: true, null_through: true }).serialize(1) == nil
```

### #serialize(data)

Serialize the object data by the schema.

#### data [any]

Serialize target object. The serializer tries data["foo"], data[:foo] and data.foo!

## License

Zlib License

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Narazaka/json-schema-serializer.
