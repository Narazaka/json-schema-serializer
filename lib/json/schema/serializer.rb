require "json/schema/serializer/version"
require "date"
require "set"

module JSON
  class Schema
    class Serializer
      def initialize(obj, options = nil)
        @schema = options && options[:resolver] ? options[:resolver].call(obj) : obj
        @options = options || {}
      end

      def serialize(obj)
        Walker.walk(@schema, obj, true, @options)
      end

      class Walker
        class << self
          TimeWithZone = defined?(ActiveSupport::TimeWithZone) ? ActiveSupport::TimeWithZone : nil

          def walk(schema, obj, required, options)
            type = try_hash(schema, :type)
            default = try_hash(schema, :default)
            format = try_hash(schema, :format)
            obj = default if obj.nil?

            if options[:inject_key]
              inject_key = try_hash(schema, options[:inject_key])
              injector = try_hash(options[:injectors], inject_key) if inject_key
              obj = injector.new(obj) if injector
            end
            type_coerce(schema, detect_type(type, obj), format, obj, required, options)
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

          def type_coerce(schema, type, format, obj, required, options)
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

              obj.map { |item| walk(items_schema, item, true, options) }
            when "object"
              return nil if obj.nil? && options[:null_through]
              return options[:null_through] ? nil : {} if options[:guard_primitive_in_structure] && is_primitive?(obj)

              properties_schema = try_hash(schema, :properties)
              additional_properties_schema = try_hash(schema, :additionalProperties)
              required_schema = Set.new(try_hash(schema, :required)&.map(&:to_s))
              ret =
                properties_schema.map do |name, property_schema|
                  [name.to_s, walk(property_schema, try_hash(obj, name), required_schema.include?(name.to_s), options)]
                end.to_h
              if additional_properties_schema
                not_additional_keys = Set.new(properties_schema.keys.map(&:to_s))
                additional_keys = obj.keys.reject { |key| not_additional_keys.include?(key.to_s) }
                ret.merge(
                  additional_keys.map do |name|
                    [name.to_s, walk(additional_properties_schema, try_hash(obj, name), false, options)]
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
