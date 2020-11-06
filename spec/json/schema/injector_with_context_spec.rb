
class FoosInject
  include JSON::Schema::Serializer::WithContext

  def initialize(models, context = {})
    @models = models
    @context = context
  end

  def map(&block)
    context = @context.merge(alpha: { 1 => :a, 2 => :b })
    @models.map { |model| block.call(with_context!(model, context)) }
  end
end

class FooInject
  include JSON::Schema::Serializer::WithContext

  def initialize(model, context = nil) # rubocop:disable Airbnb/OptArgParameters
    @model = model
    @context = context
  end

  def bar
    with_context!(@context.merge(dot: { 1 => '.', 2 => '..' })) do
      @model[:bar]
    end
  end

  def baz
    @context[:slash][@model[:baz]]
  end
end

class BarInject
  def initialize(model, context = nil) # rubocop:disable Airbnb/OptArgParameters
    @model = model
    @context = context
  end

  def hoge
    [
      @context[:slash][@model[:hoge]],
      @context[:alpha][@model[:hoge]],
      @context[:dot][@model[:hoge]],
    ].join(" ")
  end
end

RSpec.describe JSON::Schema::Serializer do
  subject { JSON::Schema::Serializer.new(schema, options).serialize(data) }

  let(:options) { { inject_key: "injects", injectors: { Foos: FoosInject, Foo: FooInject, Bar: BarInject }, inject_context: inject_context } }

  let(:inject_context) { { slash: { 1 => "/", 2 => "//" } } }

  let(:schema) do
    {
      type: "array",
      injects: "Foos",
      items: {
        type: "object",
        properties: {
          data: {
            type: "object",
            injects: "Foo",
            properties: {
              bar: {
                type: "object",
                injects: "Bar",
                properties: {
                  hoge: {
                    type: "string",
                  },
                },
              },
              baz: {
                type: "string",
              },
            },
          },
        },
      },
    }
  end

  let(:data) do
    [
      {
        data: {
          bar: {
            hoge: 1,
          },
          baz: 2,
        },
      },
      {
        data: {
          bar: {
            hoge: 2,
          },
          baz: 1,
        },
      },
    ]
  end

  let(:results) do
    [
      {
        "data" => {
          "bar" => {
            "hoge" => "/ a .",
          },
          "baz" => "//",
        },
      },
      {
        "data" => {
          "bar" => {
            "hoge" => "// b ..",
          },
          "baz" => "/",
        },
      },
    ]
  end

  it_is_asserted_by { subject == results }
end
