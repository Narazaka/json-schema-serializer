class Inject
  def initialize(model)
    @model = model
  end

  def a
    @model[:b]
  end

  def nil?
    @model.nil?
  end
end

RSpec.describe JSON::Schema::Serializer do
  subject { JSON::Schema::Serializer.new(schema, options).serialize(data) }

  let(:data) { { b: "ccc" } }

  let(:options) { { inject_key: "injects", injectors: { Inject1: Inject } } }

  context "injected" do
    let(:schema) { { type: "object", injects: "Inject1", properties: { a: { type: "string" } } } }

    it_is_asserted_by { subject == { "a" => "ccc" } }
  end

  context "no injected" do
    let(:schema) { { type: "object", title: "Inject1", properties: { a: { type: "string" } } } }

    it_is_asserted_by { subject == { "a" => nil } }
  end

  context "injected with nil nested" do
    let(:schema) do
      {
        type: "object",
        properties: { data: { type: "object", injects: "Inject1", properties: { a: { type: "string" } } } },
      }
    end

    let(:data) { { data: nil } }
    it_is_asserted_by { subject == { "data" => nil } }
  end
end
