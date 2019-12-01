require "time"

class Foo; end

class Stringable
  def to_s
    self.class.name
  end
end

RSpec.describe JSON::Schema::Serializer do
  describe "#serialize" do
    subject { JSON::Schema::Serializer.new(schema).serialize(data) }

    describe "default" do
      let(:schema) { { type: "string", default: "def" } }

      context "from string" do
        let(:data) { "foobar" }

        it_is_asserted_by { subject == "foobar" } 
      end

      context "from null" do
        let(:data) { nil }

        it_is_asserted_by { subject == "def" } 
      end
    end

    describe "string" do
      let(:schema) { { type: "string" } }

      context "from string" do
        let(:data) { "foobar" }

        it_is_asserted_by { subject == "foobar" } 
      end

      context "from int" do
        let(:data) { 42 }

        it_is_asserted_by { subject == "42" } 
      end

      context "from float" do
        let(:data) { 42.195 }

        it_is_asserted_by { subject == "42.195" } 
      end

      context "from boolean" do
        let(:data) { false }

        it_is_asserted_by { subject == "false" } 
      end

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject == "" } 
      end

      context "from array" do
        let(:data) { [] }

        it_is_asserted_by { subject == "[]" } 
      end

      context "from obj" do
        let(:data) { {} }

        it_is_asserted_by { subject == "{}" } 
      end

      context "from class" do
        let(:data) { Foo.new }

        it_is_asserted_by { subject =~ /#<Foo/ } 
      end

      context "from stringable class" do
        let(:data) { Stringable.new }

        it_is_asserted_by { subject == "Stringable" } 
      end
    end

    describe "string(date/time)" do
      describe "date-time" do
        let(:schema) { { type: "string", format: "date-time" } }

        context "from string" do
          let(:data) { "aaa" }

          it_is_asserted_by { subject == "aaa" } 
        end

        context "from null" do
          let(:data) { nil }

          it_is_asserted_by { subject == "" } 
        end

        context "from datetime" do
          let(:data) { DateTime.parse("2019-01-01T09:00:00+0900") }

          it_is_asserted_by { subject == "2019-01-01T09:00:00+09:00" } 
        end

        context "from time" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900") }

          it_is_asserted_by { subject == "2019-01-01T09:00:00+09:00" } 
        end

        context "from date" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900").to_date }

          it_is_asserted_by { subject == "2019-01-01T00:00:00+00:00" } 
        end
      end

      describe "date" do
        let(:schema) { { type: "string", format: "date" } }

        context "from string" do
          let(:data) { "aaa" }

          it_is_asserted_by { subject == "aaa" } 
        end

        context "from null" do
          let(:data) { nil }

          it_is_asserted_by { subject == "" } 
        end

        context "from datetime" do
          let(:data) { DateTime.parse("2019-01-01T09:00:00+0900") }

          it_is_asserted_by { subject == "2019-01-01" } 
        end

        context "from time" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900") }

          it_is_asserted_by { subject == "2019-01-01" } 
        end

        context "from date" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900").to_date }

          it_is_asserted_by { subject == "2019-01-01" } 
        end
      end

      describe "time" do
        let(:schema) { { type: "string", format: "time" } }

        context "from string" do
          let(:data) { "aaa" }

          it_is_asserted_by { subject == "aaa" } 
        end

        context "from null" do
          let(:data) { nil }

          it_is_asserted_by { subject == "" } 
        end

        context "from datetime" do
          let(:data) { DateTime.parse("2019-01-01T09:00:00+0900") }

          it_is_asserted_by { subject == "09:00:00+09:00" } 
        end

        context "from time" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900") }

          it_is_asserted_by { subject == "09:00:00+09:00" } 
        end

        context "from date" do
          let(:data) { Time.parse("2019-01-01T09:00:00+0900").to_date }

          it_is_asserted_by { subject == "00:00:00+00:00" } 
        end
      end
    end

    describe "string | null" do
      let(:schema) { { type: %w[string null] } }

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject.nil? } 
      end
    end

    describe "integer" do
      let(:schema) { { type: "integer" } }

      context "from string" do
        let(:data) { "42" }

        it_is_asserted_by { subject == 42 } 
      end

      context "from invalid string" do
        let(:data) { "foobar" }

        it_is_asserted_by { subject == 0 } 
      end

      context "from int" do
        let(:data) { 42 }

        it_is_asserted_by { subject == 42 } 
      end

      context "from float" do
        let(:data) { 42.195 }

        it_is_asserted_by { subject == 42 } 
      end

      context "from boolean" do
        let(:data) { false }

        it_is_asserted_by { subject == 0 } 
      end

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject == 0 } 
      end
    end

    describe "integer | null" do
      let(:schema) { { type: %w[integer null] } }

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject.nil? } 
      end
    end

    describe "number" do
      let(:schema) { { type: "number" } }

      context "from string" do
        let(:data) { "42" }

        it_is_asserted_by { subject == 42.0 } 
      end

      context "from invalid string" do
        let(:data) { "foobar" }

        it_is_asserted_by { subject == 0.0 } 
      end

      context "from int" do
        let(:data) { 42 }

        it_is_asserted_by { subject == 42.0 } 
      end

      context "from float" do
        let(:data) { 42.195 }

        it_is_asserted_by { subject == 42.195 } 
      end

      context "from boolean" do
        let(:data) { false }

        it_is_asserted_by { subject == 0.0 } 
      end

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject == 0.0 } 
      end
    end

    describe "number | null" do
      let(:schema) { { type: %w[number null] } }

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject.nil? } 
      end
    end

    describe "number | integer" do
      let(:schema) { { type: %w[number integer] } }

      context "from int" do
        let(:data) { 42 }

        it_is_asserted_by { subject == 42.0 } 
      end

      context "from float" do
        let(:data) { 42.195 }

        it_is_asserted_by { subject == 42.195 } 
      end

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject == 0 } 
      end
    end

    describe "string | integer" do
      let(:schema) { { type: %w[string integer] } }

      context "from int" do
        let(:data) { 42 }

        it_is_asserted_by { subject == 42 } 
      end

      context "from float" do
        let(:data) { 42.195 }

        it_is_asserted_by { subject == "42.195" } 
      end

      context "from string" do
        let(:data) { "42.195" }

        it_is_asserted_by { subject == "42.195" } 
      end

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject == "" } 
      end
    end

    describe "string | number" do
      let(:schema) { { type: %w[string number] } }

      context "from int" do
        let(:data) { 42 }

        it_is_asserted_by { subject == 42 } 
      end

      context "from float" do
        let(:data) { 42.195 }

        it_is_asserted_by { subject == 42.195 } 
      end

      context "from string" do
        let(:data) { "42.195" }

        it_is_asserted_by { subject == "42.195" } 
      end

      context "from nil" do
        let(:data) { nil }

        it_is_asserted_by { subject == "" } 
      end
    end

    describe "object" do
      let(:schema) do
        {
          type: "object",
          properties: {
            name: { type: "string" },
            count: { type: "integer" },
            obj: { type: "object", properties: { baz: { type: "boolean" } }, required: %w[baz] },
            reqobj: { type: "object", properties: { baz: { type: "boolean" } }, required: %w[baz] },
          },
          required: %w[name reqobj],
        }
      end

      context "from full" do
        let(:data) { { name: "foo", count: 2, obj: { baz: true }, reqobj: {}, none: 999 } }

        it do
          is_asserted_by do
            subject == { "name" => "foo", "count" => 2, "obj" => { "baz" => true }, "reqobj" => { "baz" => false } }
          end
        end
      end

      context "from partial" do
        let(:data) { { name: "foo" } }

        it do
          is_asserted_by do
            subject == { "name" => "foo", "count" => nil, "obj" => nil, "reqobj" => { "baz" => false } }
          end
        end
      end
    end

    describe "object with additionalProperties" do
      let(:schema) do
        {
          type: "object",
          properties: {
            name: { type: "string" },
            count: { type: "integer" },
          },
          additionalProperties: {
            type: "string",
          },
          required: %w[name],
        }
      end

      context "from full" do
        let(:data) { { name: "foo", count: "2", str1: "str1", str2: "str2" } }

        it do
          is_asserted_by do
            subject == { "name" => "foo", "count" => 2, "str1" => "str1", "str2" => "str2" }
          end
        end
      end

      context "from partial" do
        let(:data) { { str1: "str1" } }

        it do
          is_asserted_by do
            subject == { "name" => "", "count" => nil, "str1" => "str1" }
          end
        end
      end
    end

    describe "array" do
      let(:schema) do
        {
          type: "array",
          items: { type: "object", properties: { a: { type: "array", items: { type: %w[string null] } } } },
        }
      end

      context "from full" do
        let(:data) { [{ a: [1, "2", Stringable.new, nil] }] }

        it_is_asserted_by { subject == [{ "a" => ["1", "2", "Stringable", nil] }] } 
      end

      context "from partial" do
        let(:data) { [{}] }

        it_is_asserted_by { subject == [{ "a" => nil }] } 
      end

      context "from partial 2" do
        let(:data) { nil }

        it_is_asserted_by { subject == [] } 
      end
    end
  end
end
