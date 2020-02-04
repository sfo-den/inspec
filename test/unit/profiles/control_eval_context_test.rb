require "helper"
require "inspec/control_eval_context"
require "inspec/profile_context"

describe Inspec::ControlEvalContext do
  module FakeDSL
    def foobar
      "wombat"
    end
  end

  let(:control_content) do
    <<~EOF
      control 'foo' do
        describe foobar do
        end
      end

      control 'bar' do
        describe "wombat" do
          it { should_equal foobar }
        end
      end
    EOF
  end

  let(:resource_dsl) { FakeDSL }
  let(:backend) { mock }
  let(:profile_context) { Inspec::ProfileContext.new("test-profile", backend, {}) }
  let(:eval_context) do
    # Options that are mocked below are:
    # backend, conf, dependencies, require_loader, and skip_only_if_eval
    # See: `lib/inspec/control_eval_context.rb` for more details
    Inspec::ControlEvalContext.new(profile_context, resource_dsl, backend, {}, mock, mock, false)
  end

  it "provides rules with access to the given DSL" do
    profile_context.stubs(:current_load).returns({ file: "<test content>" })
    eval_context.instance_eval(control_content)
    profile_context.all_rules.each do |rule|
      # Turn each rule into an example group and run it, none of the
      # example content should raise an exception
      Inspec::Rule.prepare_checks(rule).each do |m, a, b|
        # if we require this at the top level, none of the other tests
        # in this file will run. itsfine.jpg
        require "rspec/core"
        RSpec::Core::ExampleGroup.describe(*a, &b).run
      end
    end
  end

  describe "#resource_class" do
    let(:resource_dsl) { profile_context.to_resources_dsl }
    let(:inner_context) { Inspec::ProfileContext.new("inner-context", backend, {}) }
    let(:newfoo) { mock }
    let(:control_content) do
      <<~EOF
        resource_class('profile_a', 'foobar')
      EOF
    end

    it "fails if the requested profile can't be found" do
      assert_raises(Inspec::ProfileNotFound) do
        _(eval_context.instance_eval(control_content)).must_raise
      end
    end

    it "returns the resource from a subcontext" do
      profile_context.expects(:subcontext_by_name).at_most_once.with("profile_a").returns(inner_context)
      inner_context.expects(:resource_registry).returns({ "foobar" => newfoo })
      _(eval_context.instance_eval(control_content)).must_equal newfoo
    end
  end
end
