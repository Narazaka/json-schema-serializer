require "time"

# rubocop:disable RSpec/DescribeSymbol

class Foo; end

class Stringable
  def to_s
    self.class.name
  end
end

RSpec.describe JSON::Schema::Serializer do
  describe "options" do
    subject { JSON::Schema::Serializer.new(schema, options).serialize(data) }

    describe :resolver do
      let(:schema) { { "$ref": "#/a" } }

      let(:options) { { resolver: ->(schema) { { type: :string } } } }

      let(:data) { "str" }

      it_is_asserted_by { subject == "str" }
    end

    describe :schema_key_transform_for_input do
      let(:schema) do
        { type: :object, properties: { userCount: { type: :integer } }, additionalProperties: { type: :integer } }
      end

      let(:options) { { schema_key_transform_for_input: ->(name) { name.downcase } } }

      let(:data) { { usercount: 1, itemcount: 2, propCount: 3 } }

      it_is_asserted_by { subject == { "userCount" => 1, "itemcount" => 2, "propCount" => 3 } }
    end

    describe :schema_key_transform_for_output do
      let(:schema) do
        { type: :object, properties: { userCount: { type: :integer } }, additionalProperties: { type: :integer } }
      end

      let(:options) { { schema_key_transform_for_output: ->(name) { name.downcase } } }

      let(:data) { { userCount: 1, itemcount: 2, propCount: 3 } }

      it_is_asserted_by { subject == { "usercount" => 1, "itemcount" => 2, "propcount" => 3 } }
    end

    describe "simple modifiers" do
      let(:schema) do
        {
          type: :object,
          properties: {
            str: { type: :string },
            int: { type: :integer },
            num: { type: :number },
            bool: { type: :boolean },
            arr: { type: :array, items: { type: :integer } },
            obj: { type: :object, properties: { name: { type: :string } }, required: %i[name] },
          },
          required: %i[str int num bool arr obj],
        }
      end

      describe :null_through do
        let(:options) { { null_through: true } }

        let(:data) { {} }

        let(:serialized) { { "str" => nil, "int" => nil, "num" => nil, "bool" => nil, "arr" => nil, "obj" => nil } }

        it_is_asserted_by { subject == serialized }
      end

      describe :empty_string_number_coerce_null do
        let(:options) { { empty_string_number_coerce_null: true } }

        let(:data) { { str: "", int: "", num: "", bool: "", arr: "" } }

        let(:serialized) do
          { "str" => "", "int" => nil, "num" => nil, "bool" => true, "arr" => [], "obj" => { "name" => "" } }
        end

        it_is_asserted_by { subject == serialized }
      end

      describe :empty_string_boolean_coerce_null do
        let(:options) { { empty_string_boolean_coerce_null: true } }

        let(:data) { { str: "", int: "", num: "", bool: "", arr: "" } }

        let(:serialized) do
          { "str" => "", "int" => 0, "num" => 0.0, "bool" => nil, "arr" => [], "obj" => { "name" => "" } }
        end

        it_is_asserted_by { subject == serialized }
      end

      describe :false_values do
        let(:schema) { { type: :boolean } }

        let(:options) { { false_values: [false, "", 0, nil, 1] } }

        context false do
          let(:data) { false }

          it_is_asserted_by { subject == false }
        end

        context true do
          let(:data) { true }

          it_is_asserted_by { subject == true }
        end

        context "\"\"" do
          let(:data) { "" }

          it_is_asserted_by { subject == false }
        end

        context 0 do
          let(:data) { 0 }

          it_is_asserted_by { subject == false }
        end

        context nil do
          let(:data) { nil }

          it_is_asserted_by { subject == false }
        end

        context 1 do
          let(:data) { 1 }

          it_is_asserted_by { subject == false }
        end

        context 2 do
          let(:data) { 2 }

          it_is_asserted_by { subject == true }
        end
      end

      describe :no_boolean_coerce do
        let(:schema) { { type: :boolean } }

        let(:options) { { no_boolean_coerce: true } }

        context true do
          let(:data) { true }

          it_is_asserted_by { subject == true }
        end

        context false do
          let(:data) { false }

          it_is_asserted_by { subject == false }
        end

        context 1 do
          let(:data) { 1 }

          it_is_asserted_by { subject == false }
        end

        context "a" do
          let(:data) { "a" }

          it_is_asserted_by { subject == false }
        end

        context "\"\"" do
          let(:data) { "" }

          it_is_asserted_by { subject == false }
        end

        context nil do
          let(:data) { nil }

          it_is_asserted_by { subject == false }
        end
      end

      describe :guard_primitive_in_structure do
        let(:options) { { guard_primitive_in_structure: true } }

        let(:data) { { arr: "string", obj: "string" } }

        let(:serialized) { { "str" => "", "int" => 0, "num" => 0.0, "bool" => false, "arr" => [], "obj" => {} } }

        it_is_asserted_by { subject == serialized }

        describe "with :null_through" do
          let(:options) { { guard_primitive_in_structure: true, null_through: true } }

          let(:serialized) { { "str" => nil, "int" => nil, "num" => nil, "bool" => nil, "arr" => nil, "obj" => nil } }

          it_is_asserted_by { subject == serialized }
        end
      end
    end
  end
end

# rubocop:enable RSpec/DescribeSymbol
