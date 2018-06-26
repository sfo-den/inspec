attr_names = [
  :one_level_array,
  :two_level_array,
  :one_level_hash,
  :two_level_hash,
  :hash_of_arrays,
  :array_of_hashes,
]
attrs = {}
attr_names.each do |attr_name|
  # Store as a symbol-fetched attribute
  attrs[attr_name] = attribute(attr_name, default: "#{attr_name}_sym_default")
  # .. and store under a string name, as a string-fetched attribute!
  attrs[attr_name.to_s] = attribute(attr_name.to_s, default: "#{attr_name}_str_default")
end

# For now, these all use string keys, as that is normal InSpec behavior
# Also, for 'its' calls, see https://github.com/rspec/rspec-its#usage
control 'nested' do

  describe 'one_level_array' do
    subject { attrs['one_level_array'] }
    it { should be_a_kind_of(Array) }
    it { should respond_to(:[])}
    its([0]) { should eq 'thing1' }
    its([1]) { should eq 'thing2' }
    # Should this be nil? Or one_level_array_default?
    its([2]) { should be nil }
  end

  describe 'two_level_array' do
    # Access first row
    subject { attrs['two_level_array'][0] }
    it { should be_a_kind_of(Array) }
    it { should respond_to(:[])}
    its([0]) { should eq 'row1col1' }
    its([1]) { should eq 'row1col2' }
  end

  describe 'one_level_hash' do
    subject { attrs['one_level_hash'] }
    it { should be_a_kind_of(Hash) }
    it { should respond_to(:[])}
    its(['key1']) { should eq 'value1' }
    its(['key2']) { should eq 'value2' }
    its('keys.count') { should eq 2 }
  end

  describe 'two_level_hash' do
    subject { attrs['two_level_hash'] }
    it { should be_a_kind_of(Hash) }
    it { should respond_to(:[])}
    its(['key1', 'key11']) { should eq 'value11' }
    its(['key2', 'key22']) { should eq 'value22' }
    its('keys.count') { should eq 2 }
  end

  describe 'hash_of_arrays' do
    subject { attrs['hash_of_arrays'] }
    it { should be_a_kind_of(Hash) }
    it { should respond_to(:[])}
    its(['key1', 0]) { should eq 'thing11' }
    its(['key2', 1]) { should eq 'thing22' }
    its('keys.count') { should eq 2 }
  end

  describe 'array_of_hashes' do
    subject { attrs['array_of_hashes'] }
    it { should be_a_kind_of(Array) }
    it { should respond_to(:[])}

    # These fail
    # its([0, 'key11']) { should eq 'value11' }
    # its([1, 'key22']) { should eq 'value22' }
    its('count') { should eq 2 }
  end
end