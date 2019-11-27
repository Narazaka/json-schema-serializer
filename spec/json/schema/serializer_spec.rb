require "time"

class Foo
end

class Stringable
  def to_s
    self.class.name
  end
end

RSpec.describe JSON::Schema::Serializer do
  describe "#serialize" do
    subject { JSON::Schema::Serializer.new(schema).serialize(data) }
    describe "string" do
      let(:schema) { { type: "string" } }

      context "from string" do
        let(:data) { "foobar" }
        it do
          is_asserted_by { subject == "foobar" }
        end
      end
      context "from int" do
        let(:data) { 42 }
        it do
          is_asserted_by { subject == "42" }
        end
      end
      context "from float" do
        let(:data) { 42.195 }
        it do
          is_asserted_by { subject == "42.195" }
        end
      end
      context "from boolean" do
        let(:data) { false }
        it do
          is_asserted_by { subject == "false" }
        end
      end
      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == "" }
        end
      end
      context "from array" do
        let(:data) { [] }
        it do
          is_asserted_by { subject == "[]" }
        end
      end
      context "from obj" do
        let(:data) { {} }
        it do
          is_asserted_by { subject == "{}" }
        end
      end
      context "from class" do
        let(:data) { Foo.new }
        it do
          is_asserted_by { subject =~ /#<Foo/ }
        end
      end
      context "from stringable class" do
        let(:data) { Stringable.new }
        it do
          is_asserted_by { subject == "Stringable" }
        end
      end
    end

    describe "string(date/time)" do
      describe "date-time" do
        let(:schema) { { type: "string", format: "date-time" } }

        context "from string" do
          let(:data) { "aaa" }
          it do
            is_asserted_by { subject == "aaa" }
          end
        end
        context "from null" do
          let(:data) { nil }
          it do
            is_asserted_by { subject == "" }
          end
        end
        context "from datetime" do
          let(:data) { DateTime.parse("2019-01-01T09:00:00+0900") }
          it do
            is_asserted_by { subject == "2019-01-01T09:00:00+09:00" }
          end
        end
        context "from time" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900") }
          it do
            is_asserted_by { subject == "2019-01-01T09:00:00+09:00" }
          end
        end
        context "from date" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900").to_date }
          it do
            is_asserted_by { subject == "2019-01-01T00:00:00+00:00" }
          end
        end
      end

      describe "date" do
        let(:schema) { { type: "string", format: "date" } }

        context "from string" do
          let(:data) { "aaa" }
          it do
            is_asserted_by { subject == "aaa" }
          end
        end
        context "from null" do
          let(:data) { nil }
          it do
            is_asserted_by { subject == "" }
          end
        end
        context "from datetime" do
          let(:data) { DateTime.parse("2019-01-01T09:00:00+0900") }
          it do
            is_asserted_by { subject == "2019-01-01" }
          end
        end
        context "from time" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900") }
          it do
            is_asserted_by { subject == "2019-01-01" }
          end
        end
        context "from date" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900").to_date }
          it do
            is_asserted_by { subject == "2019-01-01" }
          end
        end
      end

      describe "time" do
        let(:schema) { { type: "string", format: "time" } }

        context "from string" do
          let(:data) { "aaa" }
          it do
            is_asserted_by { subject == "aaa" }
          end
        end
        context "from null" do
          let(:data) { nil }
          it do
            is_asserted_by { subject == "" }
          end
        end
        context "from datetime" do
          let(:data) { DateTime.parse("2019-01-01T09:00:00+0900") }
          it do
            is_asserted_by { subject == "09:00:00+09:00" }
          end
        end
        context "from time" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900") }
          it do
            is_asserted_by { subject == "09:00:00+09:00" }
          end
        end
        context "from date" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900").to_date }
          it do
            is_asserted_by { subject == "00:00:00+00:00" }
          end
        end
      end
    end

    describe "string | null" do
      let(:schema) { { type: ["string", "null"] } }

      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == nil }
        end
      end
    end

    describe "integer" do
      let(:schema) { { type: "integer" } }

      context "from string" do
        let(:data) { "42" }
        it do
          is_asserted_by { subject == 42 }
        end
      end
      context "from invalid string" do
        let(:data) { "foobar" }
        it do
          is_asserted_by { subject == 0 }
        end
      end
      context "from int" do
        let(:data) { 42 }
        it do
          is_asserted_by { subject == 42 }
        end
      end
      context "from float" do
        let(:data) { 42.195 }
        it do
          is_asserted_by { subject == 42 }
        end
      end
      context "from boolean" do
        let(:data) { false }
        it do
          is_asserted_by { subject == 0 }
        end
      end
      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == 0 }
        end
      end
    end

    describe "integer | null" do
      let(:schema) { { type: ["integer", "null"] } }

      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == nil }
        end
      end
    end

    describe "number" do
      let(:schema) { { type: "number" } }

      context "from string" do
        let(:data) { "42" }
        it do
          is_asserted_by { subject == 42.0 }
        end
      end
      context "from invalid string" do
        let(:data) { "foobar" }
        it do
          is_asserted_by { subject == 0.0 }
        end
      end
      context "from int" do
        let(:data) { 42 }
        it do
          is_asserted_by { subject == 42.0 }
        end
      end
      context "from float" do
        let(:data) { 42.195 }
        it do
          is_asserted_by { subject == 42.195 }
        end
      end
      context "from boolean" do
        let(:data) { false }
        it do
          is_asserted_by { subject == 0.0 }
        end
      end
      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == 0.0 }
        end
      end
    end

    describe "number | null" do
      let(:schema) { { type: ["number", "null"] } }

      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == nil }
        end
      end
    end

    describe "number | integer" do
      let(:schema) { { type: ["number", "integer"] } }

      context "from int" do
        let(:data) { 42 }
        it do
          is_asserted_by { subject == 42.0 }
        end
      end
      context "from float" do
        let(:data) { 42.195 }
        it do
          is_asserted_by { subject == 42.195 }
        end
      end
      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == 0 }
        end
      end
    end

    describe "string | integer" do
      let(:schema) { { type: ["string", "integer"] } }

      context "from int" do
        let(:data) { 42 }
        it do
          is_asserted_by { subject == 42 }
        end
      end
      context "from float" do
        let(:data) { 42.195 }
        it do
          is_asserted_by { subject == "42.195" }
        end
      end
      context "from string" do
        let(:data) { "42.195" }
        it do
          is_asserted_by { subject == "42.195" }
        end
      end
      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == "" }
        end
      end
    end

    describe "string | number" do
      let(:schema) { { type: ["string", "number"] } }

      context "from int" do
        let(:data) { 42 }
        it do
          is_asserted_by { subject == 42 }
        end
      end
      context "from float" do
        let(:data) { 42.195 }
        it do
          is_asserted_by { subject == 42.195 }
        end
      end
      context "from string" do
        let(:data) { "42.195" }
        it do
          is_asserted_by { subject == "42.195" }
        end
      end
      context "from nil" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == "" }
        end
      end
    end

    describe "object" do
      let(:schema) do
        {
          type: "object",
          properties: {
            name: {
              type: "string",
            },
            count: {
              type: "integer",
            },
            obj: {
              type: "object",
              properties: {
                baz: {
                  type: "boolean"
                }
              },
              required: ["baz"]
            },
            reqobj: {
              type: "object",
              properties: {
                baz: {
                  type: "boolean"
                }
              },
              required: ["baz"]
            },
          },
          required: ["name", "reqobj"],
        }
      end

      context "from full" do
        let(:data) do
          {
            name: "foo",
            count: 2,
            obj: {
              baz: true,
            },
            reqobj: {

            },
            none: 999,
          }
        end
        it do
          is_asserted_by { subject == { "name" => "foo", "count" => 2, "obj" => { "baz" => true }, "reqobj"=>{ "baz" => false } } }
        end
      end

      context "from partial" do
        let(:data) do
          {
            name: "foo",
          }
        end
        it do
          is_asserted_by { subject == { "name" => "foo", "count" => nil, "obj" => nil, "reqobj"=>{ "baz" => false } } }
        end
      end
    end

    describe "array" do
      let(:schema) do
        {
          type: "array",
          items: {
            type: "object",
            properties: {
              a: {
                type: "array",
                items: {
                  type: ["string", "null"],
                },
              },
            },
          },
        }
      end

      context "from full" do
        let(:data) { [{a: [1, "2", Stringable.new, nil]}] }
        it do
          is_asserted_by { subject == [{"a" => ["1", "2", "Stringable", nil]}] }
        end
      end

      context "from partial" do
        let(:data) { [{}] }
        it do
          is_asserted_by { subject == [{"a" => nil}] }
        end
      end

      context "from partial 2" do
        let(:data) { nil }
        it do
          is_asserted_by { subject == [] }
        end
      end
    end
  end
end
