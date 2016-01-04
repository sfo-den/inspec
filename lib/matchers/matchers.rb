# encoding: utf-8
# copyright: 2015, Vulcano Security GmbH
# author: Dominik Richter
# author: Christoph Hartmann
# license: All rights reserved

RSpec::Matchers.define :be_readable do
  match do |file|
    file.readable?(@by, @by_user)
  end

  chain :by do |by|
    @by = by
  end

  chain :by_user do |by_user|
    @by_user = by_user
  end

  description do
    res = 'be readable'
    res += " by #{@by}" unless @by.nil?
    res += " by user #{@by_user}" unless @by_user.nil?
    res
  end
end

RSpec::Matchers.define :be_writable do
  match do |file|
    file.writable?(@by, @by_user)
  end

  chain :by do |by|
    @by = by
  end

  chain :by_user do |by_user|
    @by_user = by_user
  end

  description do
    res = 'be writable'
    res += " by #{@by}" unless @by.nil?
    res += " by user #{@by_user}" unless @by_user.nil?
    res
  end
end

RSpec::Matchers.define :be_executable do
  match do |file|
    file.executable?(@by, @by_user)
  end

  chain :by do |by|
    @by = by
  end

  chain :by_user do |by_user|
    @by_user = by_user
  end

  description do
    res = 'be executable'
    res += " by #{@by}" unless @by.nil?
    res += " by user #{@by_user}" unless @by_user.nil?
    res
  end
end

# matcher to check /etc/passwd, /etc/shadow and /etc/group
RSpec::Matchers.define :contain_legacy_plus do
  match do |file|
    file.content.match(/^\+:/)
  end
end

# verifies that no entry in an array contains a value
RSpec::Matchers.define :contain_match do |regex|
  match do |arr|
    arr.inject { |result, i|
      result = i.match(regex)
      result || i.match(/$/)
    }
  end
end

RSpec::Matchers.define :contain_duplicates do
  match do |arr|
    dup = arr.select { |element| arr.count(element) > 1 }
    !dup.uniq.empty?
  end
end

# for packages
RSpec::Matchers.define :be_installed do
  match do |package|
    package.installed? == true
  end

  failure_message do |package|
    "expected that `#{package}` is installed"
  end

  chain :by do
    fail "[UNSUPPORTED] Please use the new resources 'gem', 'npm' or 'pip'."
  end

  chain :with_version do |version|
    warn "[DEPRECATION] `with_version` is deprecated.  Please use `its(:version) { should eq '1.4.1' }` instead."
    @version = version
  end
end

# for services
RSpec::Matchers.define :be_enabled do
  match do |service|
    service.enabled? == true
  end

  chain :with_level do |_level|
    fail '[UNSUPPORTED] with level is not supported'
  end

  failure_message do |service|
    "expected that `#{service}` is enabled"
  end
end

# service resource matcher for serverspec compatibility
# Deprecated: You should not use this matcher anymore
RSpec::Matchers.define :be_running do
  match do |service|
    service.running? == true
  end

  chain :under do |_under|
    fail '[UNSUPPORTED] under is not supported'
  end

  failure_message do |service|
    "expected that `#{service}` is running"
  end
end

# user resource matcher for serverspec compatibility
# Deprecated: You should not use this matcher anymore
RSpec::Matchers.define :belong_to_group do |compare_group|
  match do |user|
    warn "[DEPRECATION] `belong_to_group` is deprecated.  Please use `its(:groups) { should include('root') }` instead."
    user.groups.include?(compare_group)
  end

  failure_message do |group|
    "expected that the user belongs to group `#{group}`"
  end
end

# user resource matcher for serverspec compatibility
# Deprecated: You should not use this matcher anymore
RSpec::Matchers.define :belong_to_primary_group do |compare_group|
  match do |user|
    warn "[DEPRECATION] `belong_to_primary_group` is deprecated.  Please use `its(:group) { should eq 'root' }` instead."
    user.group == compare_group
  end

  failure_message do |group|
    "expected that the user belongs to primary group `#{group}`"
  end
end

# matcher to check if host is reachable
RSpec::Matchers.define :be_reachable do
  match do |host|
    host.reachable? == true
  end

  chain :with do |_attr|
    fail '[UNSUPPORTED] `with` is not supported in combination with `be_reachable`'
  end

  failure_message do |host|
    "expected that host #{host} is reachable"
  end
end

# matcher to check if host is resolvable
RSpec::Matchers.define :be_resolvable do
  match do |host|
    host.resolvable? == true
  end

  chain :by do |_type|
    fail "[UNSUPPORTED] `by` is not supported in combination with `be_resolvable`. Please use the following syntax `host('example.com', port: 53, proto: 'udp')`."
  end

  failure_message do |host|
    "expected that host #{host} is resolvable"
  end
end

# matcher for iptables
RSpec::Matchers.define :have_rule do |rule|
  match do |tables|
    tables.has_rule?(rule)
  end

  chain :with_table do |_table|
    fail "[UNSUPPORTED] `with_table` is not supported in combination with `have_rule`. Please use the following syntax `iptables(table:'mangle', chain: 'input')`."
  end

  chain :with_chain do |_chain|
    fail "[UNSUPPORTED] `with_table` is not supported in combination with `with_chain`. Please use the following syntax `iptables(table:'mangle', chain: 'input')`."
  end
end

# unsupported
RSpec::Matchers.define :contain do |_rule|
  match do |_resource|
    fail "[UNSUPPORTED] `contain` matcher. Please use the following syntax `its('content') { should match('value') }`."
  end
end

# This matcher implements a compare feature that cannot be covered by the default
# `eq` matcher
# You can use it in the following cases:
# - compare strings case-insensitive
# - you expect a number (strings will be converted if possible)
#
RSpec::Matchers.define :cmp do |expected|

  def integer?(value)
    return true if value =~ /\A\d+\Z/
    false
  end

  def float?(value)
    return true if Float(value)
    false
  rescue ArgumentError => _ex
    false
  end

  def octal?(value)
    return true if value =~ /\A0+\d+\Z/
    false
  end

  match do |actual|
    # if actual and expected are strings
    if expected.is_a?(String) && actual.is_a?(String)
      actual.casecmp(expected) == 0
    elsif expected.is_a?(Integer) && integer?(actual)
      expected == actual.to_i
    elsif expected.is_a?(Float) && float?(actual)
      expected == actual.to_f
    elsif octal?(expected) && actual.is_a?(Integer)
      expected.to_i(8) == actual
    # fallback to equal
    else
      actual == expected
    end
  end

  failure_message do |actual|
    actual = '0' + actual.to_s(8) if octal?(expected)
    "\nexpected: #{expected}\n     got: #{actual}\n\n(compared using `cmp` matcher)\n"
  end

  failure_message_when_negated do |actual|
    actual = '0' + actual.to_s(8) if octal?(expected)
    "\nexpected: value != #{expected}\n     got: #{actual}\n\n(compared using `cmp` matcher)\n"
  end
end

# user resource matcher for serverspec compatibility
# This matcher will be deprecated in future
RSpec::Matchers.define :be_mounted do
  match do |path|
    if !@options.nil?
      path.mounted?(@options, @identical)
    else
      path.mounted?
    end
  end

  chain :with do |attr|
    @options = attr
    @identical = false
  end

  chain :only_with do |attr|
    @options = attr
    @identical = true
  end

  failure_message do |path|
    if !@options.nil?
      "\n#{path} is not mounted with the options\n     expected: #{@options}\n     got: #{path.mount_options}\n"
    else
      "\n#{path} is not mounted\n"
    end
  end
end
