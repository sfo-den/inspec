# encoding: utf-8
# author: Dominik Richter
# author: Stephan Renatus
# author: Christoph Hartmann

module FilterTable
  module Show; end

  class Trace
    def initialize
      @chain = []
    end

    %w{== != >= > < <= =~ !~}.each do |m|
      define_method m.to_sym do |*args|
        res = Trace.new
        @chain.push([[m.to_sym] + args, res])
        res
      end
    end

    def method_missing(*args)
      res = Trace.new
      @chain.push([args, res])
      res
    end

    def self.to_ruby(trace)
      chain = trace.instance_variable_get(:@chain)
      return '' if chain.empty?
      ' ' + chain.map do |el|
        m = el[0][0]
        args = el[0].drop(1)
        nxt = to_ruby(el[1])
        next m.to_s + nxt if args.empty?
        next m.to_s + ' ' + args[0].inspect + nxt if args.length == 1
        m.to_s + '(' + args.map(&:inspect).join(', ') + ')' + nxt
      end.join(' ')
    end
  end

  class Table
    attr_reader :params
    def initialize(resource, params, filters)
      @resource = resource
      @params = params
      @filters = filters
    end

    def where(conditions = {}, &block)
      return self if !conditions.is_a?(Hash)
      return self if conditions.empty? && !block_given?

      filters = ''
      table = @params
      conditions.each do |field, condition|
        filters += " #{field} == #{condition.inspect}"
        table = filter_lines(table, field, condition)
      end

      if block_given?
        table = table.find_all { |e| new_entry(e, '').instance_eval(&block) }
        src = Trace.new
        src.instance_eval(&block)
        filters += Trace.to_ruby(src)
      end

      self.class.new(@resource, table, @filters + filters)
    end

    def new_entry(*_)
      fail "#{self.class} must not be used on its own. It must be inherited "\
           'and the #new_entry method must be implemented. This is an internal '\
           'error and should not happen.'
    end

    def entries
      f = @resource.to_s + @filters.to_s + ' one entry'
      @params.map do |line|
        new_entry(line, f)
      end
    end

    def get_fields(*fields)
      @params.map do |line|
        fields.map { |f| line[f] }
      end.flatten
    end

    def to_s
      @resource.to_s + @filters
    end

    alias inspect to_s

    private

    def matches_float(x, y)
      return false if x.nil?
      return false if !x.is_a?(Float) && (x =~ /\A[-+]?(\d+\.?\d*|\.\d+)\z/).nil?
      x.to_f == y
    end

    def matches_int(x, y)
      return false if x.nil?
      return false if !x.is_a?(Integer) && (x =~ /\A[-+]?\d+\z/).nil?
      x.to_i == y
    end

    def matches_regex(x, y)
      return x == y if x.is_a?(Regexp)
      !x.to_s.match(y).nil?
    end

    def matches(x, y)
      x === y # rubocop:disable Style/CaseEquality
    end

    def filter_lines(table, field, condition)
      m = case condition
          when Float   then method(:matches_float)
          when Integer then method(:matches_int)
          when Regexp  then method(:matches_regex)
          else              method(:matches)
          end

      table.find_all do |line|
        next unless line.key?(field)
        m.call(line[field], condition)
      end
    end
  end

  class Factory
    def initialize
      @accessors = []
      @fields = {}
      @blocks = {}
    end

    def connect(resource, table_accessor) # rubocop:disable Metrics/AbcSize
      # create the table structure
      fields = @fields
      blocks = @blocks
      struct_fields = fields.values

      # the struct to hold single items from the #entries method
      entry_struct = Struct.new(*struct_fields.map(&:to_sym)) do
        attr_accessor :__filter
        def to_s # rubocop:disable Lint/NestedMethodDefinition
          @__filter || super
        end
      end unless struct_fields.empty?

      # the main filter table
      table = Class.new(Table) {
        fields.each do |method, field_name|
          block = blocks[method]
          define_method method.to_sym do |condition = Show, &cond_block|
            return block.call(self, condition) unless block.nil?
            return where(nil).get_fields(field_name) if condition == Show && !block_given?
            where({ field_name => condition }, &cond_block)
          end
        end

        define_method :new_entry do |hashmap, filter = ''|
          return entry_struct.new if hashmap.nil?
          res = entry_struct.new(*struct_fields.map { |x| hashmap[x] })
          res.__filter = filter
          res
        end
      }

      # define all access methods with the parent resource
      accessors = @accessors + @fields.keys
      accessors.each do |method_name|
        resource.send(:define_method, method_name.to_sym) do |*args, &block|
          filter = table.new(self, method(table_accessor).call, ' with')
          filter.method(method_name.to_sym).call(*args, &block)
        end
      end
    end

    def add_accessor(method_name)
      if method_name.nil?
        throw RuntimeError, "Called filter.add_delegator for resource #{@resource} with method name nil!"
      end
      @accessors.push(method_name)
      self
    end

    def add(method_name, opts = {}, &block)
      if method_name.nil?
        throw RuntimeError, "Called filter.add for resource #{@resource} with method name nil!"
      end

      field_name = opts[:field] || method_name
      @fields[method_name.to_sym] = field_name
      @blocks[method_name.to_sym] = block
      self
    end
  end

  def self.create
    Factory.new
  end
end
