require "time"

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

    describe :input_key_transform do
      let(:schema) do
        {
          type: :object,
          properties: {
            userCount: { type: :integer }
          },
          additionalProperties: {
            type: :integer
          }
        }
      end

      let(:options) do
        {
          input_key_transform: ->(name) { name.downcase }
        }
      end

      let(:data) do
        { usercount: 1, itemcount: 2, propCount: 3 }
      end

      it_is_asserted_by { subject == { "userCount" => 1, "itemcount" => 2, "propCount" => 3 } }
    end

    describe :output_key_transform do
      let(:schema) do
        {
          type: :object,
          properties: {
            userCount: { type: :integer }
          },
          additionalProperties: {
            type: :integer
          }
        }
      end

      let(:options) do
        {
          output_key_transform: ->(name) { name.downcase }
        }
      end

      let(:data) do
        { userCount: 1, itemcount: 2, propCount: 3 }
      end

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
            arr: {
              type: :array,
              items: {
                type: :integer,
              }
            },
            obj: {
              type: :object,
              properties: {
                name: { type: :string }
              },
              required: [:name]
            },
          },
          required: [:str, :int, :num, :bool, :arr, :obj]
        }
      end

      describe :null_through do
  
        let(:options) do
          {
            null_through: true
          }
        end
  
        let(:data) do
          {}
        end
  
        let(:serialized) do
          {
            "str" => nil,
            "int" => nil,
            "num" => nil,
            "bool" => nil,
            "arr" => nil,
            "obj" => nil,
          }
        end
  
        it_is_asserted_by { subject == serialized }
      end
      
      describe :empty_string_number_coerce_null do
        let(:options) do
          {
            empty_string_number_coerce_null: true
          }
        end

        let(:data) do
          {
            str: "",
            int: "",
            num: "",
            bool: "",
            arr: "",
          }
        end

        let(:serialized) do
          {
            "str" => "",
            "int" => nil,
            "num" => nil,
            "bool" => true,
            "arr" => [],
            "obj" => { "name" => "" }
          }
        end
  
        it_is_asserted_by { subject == serialized }
      end
      
      describe :empty_string_boolean_coerce_null do
        let(:options) do
          {
            empty_string_boolean_coerce_null: true
          }
        end

        let(:data) do
          {
            str: "",
            int: "",
            num: "",
            bool: "",
            arr: "",
          }
        end

        let(:serialized) do
          {
            "str" => "",
            "int" => 0,
            "num" => 0.0,
            "bool" => nil,
            "arr" => [],
            "obj" => { "name" => "" }
          }
        end
  
        it_is_asserted_by { subject == serialized }
      end
      
      describe :false_values do
        let(:schema) do
          { type: :boolean }
        end

        let(:options) do
          {
            false_values: [false, "", 0, nil, 1]
          }
        end

        context false do
          let(:data) { false }
    
          it_is_asserted_by { subject == false }
        end

        context true do
          let(:data) { true }
    
          it_is_asserted_by { subject == true }
        end

        context '""' do
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
        let(:schema) do
          { type: :boolean }
        end

        let(:options) do
          {
            no_boolean_coerce: true
          }
        end

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
        context '""' do
          let(:data) { "" }
          it_is_asserted_by { subject == false }
        end
        context nil do
          let(:data) { nil }
          it_is_asserted_by { subject == false }
        end
      end

      describe :guard_primitive_in_structure do
        let(:options) do
          {guard_primitive_in_structure: true}
        end

        let(:data) do
          {
            arr: "string",
            obj: "string",
          }
        end

        let(:serialized) do
          {
            "str" => "",
            "int" => 0,
            "num" => 0.0,
            "bool" => false,
            "arr" => [],
            "obj" => {}
          }
        end

        it_is_asserted_by {subject == serialized}

        describe "with :null_through" do
          let(:options) do
            {guard_primitive_in_structure: true, null_through: true}
          end

          let(:serialized) do
            {
              "str" => nil,
              "int" => nil,
              "num" => nil,
              "bool" => nil,
              "arr" => nil,
              "obj" => nil
            }
          end

          it_is_asserted_by {subject == serialized}
        end
      end
    end
  end
end
