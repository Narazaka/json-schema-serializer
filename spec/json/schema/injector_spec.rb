class Inject
  def initialize(model)
    @model = model
  end

  def a
    @model[:b]
  end
end

RSpec.describe JSON::Schema::Serializer do
  let(:data) do
    {
      b: "ccc",
    }
  end

  let(:options) do
    {
      inject_key: "injects",
      injectors: {
        Inject1: Inject,
      },
    }
  end

  subject { JSON::Schema::Serializer.new(schema, options).serialize(data) }

  context "injected" do
    let(:schema) do
      {
        type: "object",
        injects: "Inject1",
        properties: {
          a: {
            type: "string",
          },
        },
      }
    end

    it_is_asserted_by { subject == { "a" => "ccc" } }
  end

  context "no injected" do
    let(:schema) do
      {
        type: "object",
        title: "Inject1",
        properties: {
          a: {
            type: "string",
          },
        },
      }
    end

    it_is_asserted_by { subject == { "a" => nil } }
  end


end
