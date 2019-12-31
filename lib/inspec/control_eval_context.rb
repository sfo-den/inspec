require "inspec/dsl"
require "inspec/dsl_shared"
require "rspec/core/dsl"

module Inspec
  #
  # ControlEvalContext constructs an anonymous class that control
  # files will be instance_exec'd against.
  #
  # The anonymous class includes the given passed resource_dsl as well
  # as the basic DSL of the control files (describe, control, title,
  # etc).
  #
  class ControlEvalContext
    include Inspec::DSL
    include Inspec::DSL::RequireOverride

    class << self
      attr_accessor :profile_context_owner
      attr_accessor :profile_id
      attr_accessor :resources_dsl
    end

    # Creates the heart of the control eval context:
    #
    # An instantiated object which has all resources registered to it
    # and exposes them to the test file.
    #
    # @param profile_context [Inspec::ProfileContext]
    # @param outer_dsl [OuterDSLClass]
    # @return [ProfileContextClass]
    def self.create(profile_context, resources_dsl)
      klass = Class.new self
      klass.include resources_dsl

      klass.profile_context_owner = profile_context
      klass.profile_id            = profile_context.profile_id
      klass.resources_dsl         = resources_dsl

      klass
    end

    attr_accessor :skip_file

    def initialize(backend, conf, dependencies, require_loader, skip_only_if_eval)
      @backend = backend
      @conf = conf
      @dependencies = dependencies
      @require_loader = require_loader
      @skip_file_message = nil
      @skip_file = false
      @skip_only_if_eval = skip_only_if_eval
    end

    def to_s
      "Control Evaluation Context (#{profile_name})"
    end

    def profile_context_owner
      self.class.profile_context_owner
    end

    def profile_id
      self.class.profile_id
    end

    def resources_dsl
      self.class.resources_dsl
    end

    def title(arg)
      profile_context_owner.set_header(:title, arg)
    end

    def profile_name
      profile_id
    end

    def control(id, opts = {}, &block)
      opts[:skip_only_if_eval] = @skip_only_if_eval

      register_control(Inspec::Rule.new(id, profile_id, resources_dsl, opts, &block))
    end
    alias rule control

    # Describe allows users to write rspec-like bare describe
    # blocks without declaring an inclosing control. Here, we
    # generate a control for them automatically and then execute
    # the describe block in the context of that control.
    #
    def describe(*args, &block)
      loc = block_location(block, caller(1..1).first)
      id = "(generated from #{loc} #{SecureRandom.hex})"

      res = nil
      rule = Inspec::Rule.new(id, profile_id, resources_dsl, {}) do
        res = describe(*args, &block)
      end
      register_control(rule, &block)

      res
    end

    def add_resource(name, new_res)
      resources_dsl.module_exec do
        define_method name.to_sym do |*args|
          new_res.new(@backend, name.to_s, *args)
        end
      end
    end

    def add_resources(context)
      # # TODO: write real unit tests for this and then make this change:
      # dsl = context.to_resources_dsl
      # self.class.include dsl
      # Inspec::Rule.include dsl

      self.class.class_eval do
        include context.to_resources_dsl
      end

      # TODO: seriously consider getting rid of the NPM model
      extend context.to_resources_dsl
    end

    def add_subcontext(context)
      profile_context_owner.add_subcontext(context)
    end

    def register_control(control, &block)
      if @skip_file
        ::Inspec::Rule.set_skip_rule(control, true, @skip_file_message)
      end

      unless profile_context_owner.profile_supports_platform?
        platform = inspec.platform
        msg = "Profile `#{profile_context_owner.profile_id}` is not supported on platform #{platform.name}/#{platform.release}."
        ::Inspec::Rule.set_skip_rule(control, true, msg)
      end

      unless profile_context_owner.profile_supports_inspec_version?
        msg = "Profile `#{profile_context_owner.profile_id}` is not supported on InSpec version (#{Inspec::VERSION})."
        ::Inspec::Rule.set_skip_rule(control, true, msg)
      end

      profile_context_owner.register_rule(control, &block) unless control.nil?
    end

    def input(input_name, options = {})
      if options.empty?
        # Simply an access, no event here
        Inspec::InputRegistry.find_or_register_input(input_name, profile_id).value
      else
        options[:priority] ||= 20
        options[:provider] = :inline_control_code
        evt = Inspec::Input.infer_event(options)
        Inspec::InputRegistry.find_or_register_input(input_name, profile_id, event: evt).value
      end
    end

    # Find the Input object, but don't collapse to a value.
    # Will return nil on a miss.
    def input_object(input_name)
      Inspec::InputRegistry.find_or_register_input(input_name, profile_id)
    end

    def attribute(name, options = {})
      Inspec.deprecate(:attrs_dsl, "Input name: #{name}, Profile: #{profile_id}")
      input(name, options)
    end

    def skip_control(id)
      profile_context_owner.unregister_rule(id)
    end
    alias skip_rule skip_control

    def only_if(message = nil, &block)
      return unless block
      return if @skip_file == true
      return if @skip_only_if_eval == true

      return if block.yield == true

      # Apply `set_skip_rule` for other rules in the same file
      profile_context_owner.rules.values.each do |r|
        sources_match = r.source_file == block.source_location[0]
        Inspec::Rule.set_skip_rule(r, true, message) if sources_match
      end

      @skip_file_message = message
      @skip_file = true
    end

    private

    def block_location(block, alternate_caller)
      if block.nil?
        alternate_caller[/^(.+:\d+):in .+$/, 1] || "unknown"
      else
        path, line = block.source_location
        "#{File.basename(path)}:#{line}"
      end
    end
  end
end
