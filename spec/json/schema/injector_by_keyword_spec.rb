class InjectWithContextByKeyword
  def initialize(data:, context: nil)
    @model = data
    @context = context
  end

  def a
    @model[:b]
  end

  def c
    @context ? @context[:c] : :no_context
  end
end

RSpec.describe JSON::Schema::Serializer do
  subject { JSON::Schema::Serializer.new(schema, options).serialize(data) }

  let(:data) { { b: "ccc" } }

  let(:options) { { inject_key: "injects", injectors: { Inject1: InjectWithContextByKeyword }, inject_by_keyword: true } }

  let(:inject_context) { { c: "foo" } }

  let(:schema) do
    { type: "object", injects: "Inject1", properties: { a: { type: "string" }, c: { type: "string" } } }
  end

  context "injected" do
    it_is_asserted_by { subject == { "a" => "ccc", "c" => "no_context" } }
  end

  context "injected with context" do
    let(:options) { { inject_key: "injects", injectors: { Inject1: InjectWithContextByKeyword }, inject_context: inject_context, inject_by_keyword: true } }
  
    it_is_asserted_by { subject == { "a" => "ccc", "c" => "foo" } }
  end
end
