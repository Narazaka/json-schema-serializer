require "json/schema/serializer/version"
require "date"
require "set"

module JSON
  class Schema
    class Serializer
      def initialize(schema, options = nil) # rubocop:disable Airbnb/OptArgParameters
        @schema = options && options[:resolver] ? options[:resolver].call(schema) : schema
        @options = options || {}
      end

      def serialize(data)
        Walker.walk(@schema, data, true, false, @options)
      end

      DataWithContext = Struct.new(:data, :context, keyword_init: true)

      module WithContext
        ARG2_NOT_GIVEN = :__json_schema_serializer_arg2_not_given__

        def with_context!(arg1, arg2 = ARG2_NOT_GIVEN) # rubocop:disable Airbnb/OptArgParameters
          if block_given?
            DataWithContext.new(data: yield, context: arg1)
          elsif arg2 == ARG2_NOT_GIVEN
            DataWithContext.new(arg1)
          else
            DataWithContext.new(data: arg1, context: arg2)
          end
        end
      end

      class Walker
        class << self
          TimeWithZone = defined?(ActiveSupport::TimeWithZone) ? ActiveSupport::TimeWithZone : nil

          def walk(schema, obj, required, using_default, options)
            type = try_hash(schema, :type)
            default = try_hash(schema, :default)
            format = try_hash(schema, :format)
            if obj.nil?
              using_default = true
              obj = default
            end

            if options[:inject_key]
              inject_key = try_hash(schema, options[:inject_key])
              injector = try_hash(options[:injectors], inject_key) if inject_key
              if obj.instance_of?(JSON::Schema::Serializer::DataWithContext)
                options = options.merge(inject_context: obj.context)
                obj = obj.data
                if obj.nil?
                  using_default = true
                  obj = default
                end
              end
              if injector && !using_default
                if options[:inject_context]
                  obj =
                    if options[:inject_by_keyword]
                      injector.new(data: obj, context: options[:inject_context])
                    else
                      injector.new(obj, options[:inject_context])
                    end
                else
                  obj =
                    if options[:inject_by_keyword]
                      injector.new(data: obj)
                    else
                      injector.new(obj)
                    end
                end
              end
            end
            type_coerce(schema, detect_type(type, obj), format, obj, required, using_default, options)
          end

          def detect_type(type, obj)
            return type unless type.is_a?(Array)
            type = Set.new(type.map(&:to_s))

            case obj
            when nil
              case
              when type.include?("null")
                "null"
              else
                type.first
              end
            when DateTime, Date, Time, TimeWithZone
              case
              when type.include?("string")
                "string"
              when type.include?("number")
                "number"
              when type.include?("integer")
                "integer"
              else
                type.first
              end
            when String
              case
              when type.include?("string")
                "string"
              else
                type.first
              end
            when Integer
              case
              when type.include?("integer")
                "integer"
              when type.include?("number")
                "number"
              when type.include?("string")
                "string"
              when type.include?("boolean")
                "boolean"
              else
                type.first
              end
            when Float
              case
              when type.include?("number")
                "number"
              when type.include?("string")
                "string"
              when type.include?("integer")
                "integer"
              when type.include?("boolean")
                "boolean"
              else
                type.first
              end
            when true, false
              case
              when type.include?("boolean")
                "boolean"
              else
                type.first
              end
            when Array
              case
              when type.include?("array")
                "array"
              else
                type.first
              end
            else
              case
              when type.include?("object")
                "object"
              else
                type.first
              end
            end
          end

          def type_coerce(schema, type, format, obj, required, using_default, options)
            return nil if !required && obj.nil?

            case type.to_s
            when "null"
              nil
            when "string"
              case obj
              when nil
                options[:null_through] ? nil : ""
              when DateTime, Date, Time, TimeWithZone
                case format.to_s
                when "date-time"
                  obj.strftime("%FT%T%:z")
                when "date"
                  obj.strftime("%F")
                when "time"
                  obj.strftime("%T%:z")
                else
                  obj.to_s
                end
              when Regexp
                obj.inspect.gsub(%r{^/|/[a-z]*$}, "")
              else
                obj.to_s
              end
            when "integer"
              case obj
              when true
                1
              when false
                0
              when nil
                options[:null_through] ? nil : 0
              when ""
                options[:empty_string_number_coerce_null] ? nil : 0
              else
                obj.to_i
              end
            when "number"
              case obj
              when true
                1.0
              when false
                0.0
              when nil
                options[:null_through] ? nil : 0.0
              when ""
                options[:empty_string_number_coerce_null] ? nil : 0.0
              else
                obj.to_f
              end
            when "boolean"
              if obj.nil? && options[:null_through]
                nil
              elsif options[:empty_string_boolean_coerce_null] && obj == ""
                nil
              elsif options[:false_values]
                !options[:false_values].include?(obj)
              elsif options[:no_boolean_coerce]
                obj == true
              else
                obj ? true : false
              end
            when "array"
              items_schema = try_hash(schema, :items)
              return options[:null_through] ? nil : [] if obj.nil? || !obj.respond_to?(:map)
              return options[:null_through] ? nil : [] if options[:guard_primitive_in_structure] && is_primitive?(obj)

              obj.map { |item| walk(items_schema, item, true, using_default, options) }
            when "object"
              return nil if obj.nil? && options[:null_through]
              return options[:null_through] ? nil : {} if options[:guard_primitive_in_structure] && is_primitive?(obj)

              properties_schema = try_hash(schema, :properties)
              additional_properties_schema = try_hash(schema, :additionalProperties)
              required_schema = Set.new(try_hash(schema, :required)&.map(&:to_s))
              input_key_transform = options[:schema_key_transform_for_input] # schema key -> input obj key
              output_key_transform = options[:schema_key_transform_for_output] # schema key -> out
              ret =
                properties_schema.map do |name, property_schema|
                  input_key = input_key_transform ? input_key_transform.call(name.to_s) : name
                  output_key = output_key_transform ? output_key_transform.call(name.to_s) : name.to_s
                  [output_key, walk(property_schema, try_hash(obj, input_key), required_schema.include?(name.to_s), using_default, options)]
                end.to_h
              if additional_properties_schema
                not_additional_keys_array = properties_schema.keys.map(&:to_s)
                not_additional_keys = Set.new(input_key_transform ? not_additional_keys_array.map { |k| input_key_transform.call(k) } : not_additional_keys_array)
                additional_keys = obj.keys.reject { |key| not_additional_keys.include?(key.to_s) }
                ret.merge(
                  additional_keys.map do |name|
                    output_key = output_key_transform ? output_key_transform.call(name.to_s) : name.to_s
                    [output_key, walk(additional_properties_schema, try_hash(obj, name), false, using_default, options)]
                  end.to_h,
                )
              else
                ret
              end
            end
          end

          private

          def try_hash(obj, name)
            if obj.respond_to?(:"[]")
              obj[name] || obj[name.is_a?(String) ? name.to_sym : name.to_s]
            elsif obj.respond_to?(name)
              obj.send(name)
            end
          end

          def is_primitive?(obj)
            case obj
            when String, Integer, Float, true, false, nil
              true
            else
              false
            end
          end
        end
      end
    end
  end
end
