# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'helper'
require 'inspec/profile_context'

class Module
  include Minitest::Spec::DSL
end

module DescribeOneTest
  it 'loads an empty describe.one' do
    profile.load(format(context_format, 'describe.one'))
    get_checks.must_equal([])
  end

  it 'loads an empty describe.one block' do
    profile.load(format(context_format, 'describe.one do; end'))
    get_checks.must_equal([['describe.one', [], nil]])
  end

  it 'loads a simple describe.one block' do
    profile.load(format(context_format, '
      describe.one do
        describe true do; it { should eq true }; end
      end'))
    c = get_checks[0]
    c[0].must_equal 'describe.one'
    childs = c[1]
    childs.length.must_equal 1
    childs[0][0].must_equal 'describe'
    childs[0][1].must_equal [true]
  end

  it 'loads a complex describe.one block' do
    profile.load(format(context_format, '
      describe.one do
        describe 0 do; it { should eq true }; end
        describe 1 do; it { should eq true }; end
        describe 2 do; it { should eq true }; end
      end'))
    c = get_checks[0]
    c[0].must_equal 'describe.one'
    childs = c[1]
    childs.length.must_equal 3
    childs.each_with_index do |ci, idx|
      ci[0].must_equal 'describe'
      ci[1].must_equal [idx]
    end
  end
end

describe Inspec::ProfileContext do
  let(:backend) { MockLoader.new.backend }
  let(:profile) { Inspec::ProfileContext.new(nil, backend, {}) }

  def get_checks(rule_index = 0)
    rule = profile.rules.values[rule_index]
    Inspec::Rule.prepare_checks(rule)
  end

  it 'must be able to load empty content' do
    profile.load('', 'dummy', 1).must_be_nil
  end

  describe 'its default DSL' do
    def load(call)
      proc { profile.load(call) }
    end

    let(:context_format) { '%s' }

    include DescribeOneTest

    it 'must provide os resource' do
      load('print os[:family]').must_output 'debian'
    end

    it 'must provide file resource' do
      load('print file("").type').must_output 'unknown'
    end

    it 'must provide command resource' do
      load('print command("").stdout').must_output ''
    end

    it 'supports empty describe calls' do
      load('describe').must_output ''
      profile.rules.keys.length.must_equal 1
      profile.rules.keys[0].must_match(/^\(generated from \(eval\):1 [0-9a-f]+\)$/)
      profile.rules.values[0].must_be_kind_of Inspec::Rule
    end

    it 'provides the describe keyword in the global DSL' do
      load('describe true do; it { should_eq true }; end')
        .must_output ''
      profile.rules.keys.length.must_equal 1
      profile.rules.keys[0].must_match(/^\(generated from \(eval\):1 [0-9a-f]+\)$/)
      profile.rules.values[0].must_be_kind_of Inspec::Rule
    end

    it 'loads multiple computed calls to describe correctly' do
      load("%w{1 2 3}.each do\ndescribe true do; it { should_eq true }; end\nend")
        .must_output ''
      profile.rules.keys.length.must_equal 3
      [0, 1, 2].each do |i|
        profile.rules.keys[i].must_match(/^\(generated from \(eval\):2 [0-9a-f]+\)$/)
        profile.rules.values[i].must_be_kind_of Inspec::Rule
      end
    end

    it 'does not provide the expect keyword in the global DLS' do
      load('expect(true).to_eq true').must_raise NoMethodError
    end

    describe 'global only_if' do
      let(:if_true) { "only_if { true }\n" }
      let(:if_false) { "only_if { false }\n" }
      let(:describe) { "describe nil do its(:to_i) { should eq rand } end\n" }
      let(:control) { "control 1 do\n#{describe}\nend\n" }
      let(:control_2) { "control 2 do\n#{describe}\nend\n" }

      it 'provides the keyword' do
        profile.load(if_true)
        profile.rules.must_equal({})
      end

      it 'doesnt affect controls when positive' do
        profile.load(if_true + 'control 1')
        profile.rules.values[0].must_be_kind_of Inspec::Rule
      end

      it 'doesnt remove controls when negative' do
        profile.load(if_false + 'control 1')
        profile.rules.values[0].must_be_kind_of Inspec::Rule
      end

      it 'alters controls when positive' do
        profile.load(if_false + control)
        get_checks.length.must_equal 1
        get_checks[0][1][0].resource_skipped?.must_equal true
        get_checks[0][1][0].resource_exception_message.must_equal 'Skipped control due to only_if condition.'
        get_checks[0][1][0].resource_failed?.must_equal false
      end

      it 'alters non-controls when positive' do
        profile.load(if_false + describe)
        get_checks.length.must_equal 1
        get_checks[0][1][0].resource_skipped?.must_equal true
        get_checks[0][1][0].resource_exception_message.must_equal 'Skipped control due to only_if condition.'
        get_checks[0][1][0].resource_failed?.must_equal false
      end

      it 'doesnt alter controls when negative' do
        profile.load(if_true + control)
        get_checks.length.must_equal 1
        get_checks[0][1][0].must_be_nil
      end

      it 'doesnt alter non-controls when negative' do
        profile.load(if_true + describe)
        get_checks.length.must_equal 1
        get_checks[0][1][0].must_be_nil
      end

      it 'doesnt overwrite falsy only_ifs' do
        profile.load(if_false + if_true + control)
        get_checks.length.must_equal 1
        get_checks[0][1][0].resource_skipped?.must_equal true
        get_checks[0][1][0].resource_exception_message.must_equal 'Skipped control due to only_if condition.'
        get_checks[0][1][0].resource_failed?.must_equal false
      end

      it 'doesnt overwrite falsy only_ifs' do
        profile.load(if_true + if_false + control)
        get_checks.length.must_equal 1
        get_checks[0][1][0].resource_skipped?.must_equal true
        get_checks[0][1][0].resource_exception_message.must_equal 'Skipped control due to only_if condition.'
        get_checks[0][1][0].resource_failed?.must_equal false
      end

      it 'doesnt extend into other control files' do
        fake_control_file = if_false + control
        profile.load_control_file(fake_control_file, '(eval)', nil)
        profile.load_control_file(control_2, '(eval)', nil)
        first_file_check = get_checks(0)
        second_file_check = get_checks(1)
        first_file_check[0][1][0].resource_skipped.must_equal 'Skipped control due to only_if condition.'
        second_file_check[0][1][0].must_be_nil
      end

      it 'applies to the controls above it when at the bottom of the file' do
        fake_control_file = control + if_false
        profile.load_control_file(fake_control_file, '(eval)', 1)
        get_checks[0][1][0].resource_skipped.must_equal 'Skipped control due to only_if condition.'
      end

      it 'applies to the controls below it when at the top of the file' do
        fake_control_file = if_false + control
        profile.load_control_file(fake_control_file, '(eval)', 1)
        get_checks[0][1][0].resource_skipped.must_equal 'Skipped control due to only_if condition.'
      end

      it 'applies to the controls above and below it when at the middle of the file' do
        fake_control_file = control + if_false + control_2
        profile.load_control_file(fake_control_file, '(eval)', 1)
        check_top = get_checks(0)
        check_bottom = get_checks(1)
        check_top[0][1][0].resource_skipped.must_equal 'Skipped control due to only_if condition.'
        check_bottom[0][1][0].resource_skipped.must_equal 'Skipped control due to only_if condition.'
      end

      it 'applies to the describe blocks above and below it when at the middle of the file' do
        fake_control_file = describe + if_false + describe
        profile.load_control_file(fake_control_file, '(eval)', 1)
        check_top = get_checks(0)
        check_bottom = get_checks(1)
        check_top[0][1][0].resource_skipped.must_equal 'Skipped control due to only_if condition.'
        check_bottom[0][1][0].resource_skipped.must_equal 'Skipped control due to only_if condition.'
      end
    end

    it 'provides the control keyword in the global DSL' do
      profile.load('control 1')
      profile.rules.keys.must_equal ['1']
      profile.rules.values[0].must_be_kind_of Inspec::Rule
    end

    it 'provides the rule keyword in the global DSL (legacy mode)' do
      profile.load('rule 1')
      profile.rules.keys.must_equal ['1']
      profile.rules.values[0].must_be_kind_of Inspec::Rule
    end
  end

  describe 'rule DSL' do
    let(:rule_id) { rand.to_s }
    let(:context_format) { "rule #{rule_id.inspect} do\n%s\nend" }

    def get_rule
      profile.rules[rule_id]
    end

    include DescribeOneTest

    it 'doesnt add any checks if none are provided' do
      profile.load("rule #{rule_id.inspect}")
      rule = profile.rules[rule_id]
      ::Inspec::Rule.prepare_checks(rule).must_equal([])
    end

    describe 'supports empty describe blocks' do
      it 'doesnt crash, but doesnt add anything either' do
        profile.load(format(context_format, 'describe'))
        profile.rules.keys.must_include(rule_id)
        get_checks.must_equal([])
      end
    end

    describe 'adds a check via describe' do
      let(:check) {
        profile.load(format(context_format,
          "describe os[:family] { it { must_equal 'debian' } }"
          ))
        get_checks[0]
      }

      it 'registers the check with describe' do
        check[0].must_equal 'describe'
      end

      it 'registers the check with the describe argument' do
        check[1].must_equal %w{debian}
      end

      it 'registers the check with the provided proc' do
        check[2].must_be_kind_of Proc
      end
    end

    describe 'adds a check via expect' do
      let(:check) {
        profile.load(format(context_format,
          "expect(os[:family]).to eq('debian')"
          ))
        get_checks[0]
      }

      it 'registers the check with describe' do
        check[0].must_equal 'expect'
      end

      it 'registers the check with the describe argument' do
        check[1].must_equal %w{debian}
      end

      it 'registers the check with the provided proc' do
        check[2].must_be_kind_of Inspec::Expect
      end
    end

    describe 'adds a check via describe + expect' do
      let(:check) {
        profile.load(format(context_format,
          "describe 'the actual test' do
            expect(os[:family]).to eq('debian')
          end"
          ))
        get_checks[0]
      }

      it 'registers the check with describe' do
        check[0].must_equal 'describe'
      end

      it 'registers the check with the describe argument' do
        check[1].must_equal ['the actual test']
      end

      it 'registers the check with the provided proc' do
        check[2].must_be_kind_of Proc
      end
    end

    describe 'with only_if' do
      it 'provides the only_if keyword' do
        profile.load(format(context_format, 'only_if'))
        get_checks.must_equal([])
      end

      it 'skips with only_if == false' do
        profile.load(format(context_format, 'only_if { false }'))
        get_checks.length.must_equal 1
        get_checks[0][1][0].resource_skipped?.must_equal true
        get_checks[0][1][0].resource_exception_message.must_equal 'Skipped control due to only_if condition.'
        get_checks[0][1][0].resource_failed?.must_equal false
      end

      it 'does nothing with only_if == false' do
        profile.load(format(context_format, 'only_if { true }'))
        get_checks.length.must_equal 0
      end

      it 'doesnt overwrite falsy only_ifs' do
        profile.load(format(context_format, "only_if { false }\nonly_if { true }"))
        get_checks.length.must_equal 1
        get_checks[0][1][0].resource_skipped?.must_equal true
        get_checks[0][1][0].resource_exception_message.must_equal 'Skipped control due to only_if condition.'
        get_checks[0][1][0].resource_failed?.must_equal false
      end

      it 'doesnt overwrite falsy only_ifs' do
        profile.load(format(context_format, "only_if { true }\nonly_if { false }"))
        get_checks.length.must_equal 1
        get_checks[0][1][0].resource_skipped?.must_equal true
        get_checks[0][1][0].resource_exception_message.must_equal 'Skipped control due to only_if condition.'
        get_checks[0][1][0].resource_failed?.must_equal false
      end
    end
  end

  describe 'library loading' do
    it 'supports simple ruby require statements' do
      # Please note: we do discourage the use of Gems in inspec resources at
      # this time. Resources should be well packaged whenever possible.
      proc { profile.load('Net::POP3') }.must_raise NameError
      profile.load_libraries([['require "net/pop"', 'libraries/a.rb']])
      profile.load('Net::POP3').to_s.must_equal 'Net::POP3'
    end

    it 'supports loading across the library' do
      profile.load_libraries([
        ["require 'a'\nA", 'libraries/b.rb'],
        ['module A; end', 'libraries/a.rb']
      ])
      profile.load('A').to_s.must_equal 'A'
    end

    it 'fails loading if reference error occur' do
      proc {
        profile.load_libraries([
          ["require 'a'\nB", 'libraries/b.rb'],
          ['module A; end', 'libraries/a.rb']
        ])
      }.must_raise NameError
    end

    it 'fails loading if a reference dependency isnt found' do
      proc {
        profile.load_libraries([
          ["require 'a'\nA", 'libraries/b.rb'],
        ])
      }.must_raise LoadError
    end
  end
end
