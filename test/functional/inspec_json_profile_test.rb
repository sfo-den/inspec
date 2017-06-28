# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'functional/helper'

describe 'inspec json' do
  include FunctionalHelper

  it 'read the profile json' do
    out = inspec('json ' + example_profile)
    out.stderr.must_equal ''
    out.exit_status.must_equal 0
    s = out.stdout
    JSON.load(s).must_be_kind_of Hash
  end

  describe 'json profile data' do
    let(:json) { JSON.load(inspec('json ' + example_profile).stdout) }

    it 'has a name' do
      json['name'].must_equal 'profile'
    end

    it 'has a title' do
      json['title'].must_equal 'InSpec Example Profile'
    end

    it 'has a summary' do
      json['summary'].must_equal 'Demonstrates the use of InSpec Compliance Profile'
    end

    it 'has a version' do
      json['version'].must_equal '1.0.0'
    end

    it 'has a maintainer' do
      json['maintainer'].must_equal 'Chef Software, Inc.'
    end

    it 'has a copyright' do
      json['copyright'].must_equal 'Chef Software, Inc.'
    end

    it 'has controls' do
      json['controls'].length.must_equal 4
    end

    describe 'a control' do
      let(:control) { json['controls'].find { |x| x['id'] == 'tmp-1.0' } }

      it 'has a title' do
        control['title'].must_equal 'Create /tmp directory'
      end

      it 'has a description' do
        control['desc'].must_equal 'An optional description...'
      end

      it 'has an impact' do
        control['impact'].must_equal 0.7
      end

      it 'has a ref' do
        control['refs'].must_equal([{'ref' => 'Document A-12', 'url' => 'http://...'}])
      end

      it 'has a source location' do
        loc = File.join(example_profile, '/controls/example.rb')
        control['source_location']['ref'].must_equal loc
        control['source_location']['line'].must_equal 7
      end

      it 'has a the source code' do
        control['code'].must_match(/\Acontrol \"tmp-1.0\" do.*end\n\Z/m)
      end
    end
  end

  describe 'filter with --controls' do
    let(:out) { inspec('json ' + example_profile + ' --controls tmp-1.0') }

    it 'still succeeds' do
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
    end

    it 'only has one control included' do
      json = JSON.load(out.stdout)
      json['controls'].length.must_equal 1
      json['controls'][0]['id'].must_equal 'tmp-1.0'
      json['groups'].length.must_equal 1
      json['groups'][0]['id'].must_equal 'controls/example.rb'
    end
  end

  it 'writes json to file' do
    out = inspec('json ' + example_profile + ' --output ' + dst.path)
    out.stderr.must_equal ''
    out.exit_status.must_equal 0
    hm = JSON.load(File.read(dst.path))
    hm['name'].must_equal 'profile'
    hm['controls'].length.must_equal 4
  end
end
