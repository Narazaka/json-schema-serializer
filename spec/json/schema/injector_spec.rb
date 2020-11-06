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

class ArrayInject
  def initialize(models)
    @models = models
  end

  def map(&block)
    @models.map { |model| model.merge(b: model[:b] * 2) }.map(&block)
  end
end

RSpec.describe JSON::Schema::Serializer do
  subject { JSON::Schema::Serializer.new(schema, options).serialize(data) }

  let(:data) { { b: "ccc" } }

  let(:options) { { inject_key: "injects", injectors: { Inject1: Inject, AInject: ArrayInject } } }

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

  context "injected with default" do
    let(:schema) do
      {
        type: "object",
        injects: "Inject1",
        properties: { a: { type: "string" } },
        default: {
          a: 1
        }
      }
    end

    let(:data) { nil }

    it_is_asserted_by { subject == { "a" => "1" } }
  end

  context "injected nested with default" do
    let(:schema) do
      {
        type: "object",
        properties: {
          data: {
            type: "object",
            injects: "Inject1",
            properties: { a: { type: "string" } },
          },
        },
        default: {
          data: { a: 1 }
        }
      }
    end

    let(:data) { nil }

    it_is_asserted_by { subject == { "data" => { "a" => "1" } } }
  end

  context "injected with array" do
    let(:schema) do
      {
        type: "array",
        injects: "AInject", 
        items: {
          type: "object",
          injects: "Inject1",
          properties: { a: { type: "number" } },
        }
      }
    end

    let(:data) { [{ b: 1 }, { b: 3 }] }

    it_is_asserted_by { subject == [{ "a" => 2 }, { "a" => 6 }] }
  end
end
