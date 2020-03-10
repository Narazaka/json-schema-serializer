class InjectWithContext
  def initialize(model, context = nil)
    @model = model
    @context = context
  end

  def a
    @model[:b]
  end

  def c
    @context[:c]
  end
end

RSpec.describe JSON::Schema::Serializer do
  subject { JSON::Schema::Serializer.new(schema, options).serialize(data) }

  let(:data) { { b: "ccc" } }

  let(:options) { { inject_key: "injects", injectors: { Inject1: InjectWithContext }, inject_context: inject_context } }

  let(:inject_context) { { c: "foo" } }

  context "injected with context" do
    let(:schema) do
      { type: "object", injects: "Inject1", properties: { a: { type: "string" }, c: { type: "string" } } }
    end

    it_is_asserted_by { subject == { "a" => "ccc", "c" => "foo" } }
  end
end
