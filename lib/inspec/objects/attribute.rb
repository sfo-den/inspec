# encoding:utf-8

module Inspec
  class Attribute
    attr_accessor :name

    VALID_TYPES = %w{
      String
      Numeric
      Regexp
      Array
      Hash
      Boolean
      Any
    }.freeze

    DEFAULT_ATTRIBUTE = Class.new do
      def initialize(name)
        @name = name
      end

      def method_missing(*_)
        Inspec::Log.warn(
          "Returning DEFAULT_ATTRIBUTE for '#{@name}'. "\
          "Use --attrs to provide a value for '#{@name}' or specify a default  "\
          "value with `attribute('#{@name}', default: 'somedefault', ...)`.",
        )
        self
      end

      def respond_to_missing?(_, _)
        true
      end
    end

    def initialize(name, options = {})
      @name = name
      @opts = options
      validate_value_type(default) if @opts.key?(:type) && @opts.key?(:default)
      @value = nil
    end

    def value=(new_value)
      validate_value_type(new_value) if @opts.key?(:type)
      @value = new_value
    end

    def value
      if @value.nil?
        validate_required(@value) if @opts[:required] == true
        @value = default
      else
        @value
      end
    end

    def title
      @opts[:title]
    end

    def description
      @opts[:description]
    end

    def ruby_var_identifier
      @opts[:identifier] || 'attr_' + @name.downcase.strip.gsub(/\s+/, '-').gsub(/[^\w-]/, '')
    end

    def to_hash
      {
        name: @name,
        options: @opts,
      }
    end

    def to_ruby
      res = ["#{ruby_var_identifier} = attribute('#{@name}',{"]
      res.push "  title: '#{title}'," unless title.to_s.empty?
      res.push "  default: #{default.inspect}," unless default.to_s.empty?
      res.push "  description: '#{description}'," unless description.to_s.empty?
      res.push '})'
      res.join("\n")
    end

    def to_s
      "Attribute #{@name} with #{@value}"
    end

    private

    def validate_required(value)
      # skip if we are not doing an exec call (archive/vendor/check)
      return unless Inspec::BaseCLI.inspec_cli_command == :exec

      # value will be set already if a secrets file was passed in
      if (!@opts.key?(:default) && value.nil?) || (@opts[:default].nil? && value.nil?)
        error = Inspec::Attribute::RequiredError.new
        error.attribute_name = @name
        raise error, "Attribute '#{error.attribute_name}' is required and does not have a value."
      end
    end

    def validate_type(type)
      type = type.capitalize
      abbreviations = {
        'Num' => 'Numeric',
        'Regex' => 'Regexp',
      }
      type = abbreviations[type] if abbreviations.key?(type)
      if !VALID_TYPES.include?(type)
        error = Inspec::Attribute::TypeError.new
        error.attribute_type = type
        raise error, "Type '#{error.attribute_type}' is not a valid attribute type."
      end
      type
    end

    def valid_numeric?(value)
      Float(value)
      true
    rescue
      false
    end

    def valid_regexp?(value)
      # check for invalid regex syntex
      Regexp.new(value)
      true
    rescue
      false
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def validate_value_type(value)
      type = validate_type(@opts[:type])
      return if type == 'Any'

      invalid_type = false
      if type == 'Regexp'
        invalid_type = true if !value.is_a?(String) || !valid_regexp?(value)
      elsif type == 'Numeric'
        invalid_type = true if !valid_numeric?(value)
      elsif type == 'Boolean'
        invalid_type = true if ![true, false].include?(value)
      elsif value.is_a?(Module.const_get(type)) == false
        invalid_type = true
      end

      if invalid_type == true
        error = Inspec::Attribute::ValidationError.new
        error.attribute_name = @name
        error.attribute_value = value
        error.attribute_type = type
        raise error, "Attribute '#{error.attribute_name}' with value '#{error.attribute_value}' does not validate to type '#{error.attribute_type}'."
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def default
      @opts.key?(:default) ? @opts[:default] : DEFAULT_ATTRIBUTE.new(@name)
    end
  end
end
