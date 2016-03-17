# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'helper'

describe Fetchers::Mock do
  let(:fetcher) { Fetchers::Mock }

  it 'registers with the fetchers registry' do
    reg = Inspec::Fetcher.registry
    _(reg['mock']).must_equal fetcher
  end

  it 'wont load nil' do
    fetcher.resolve(nil).must_be :nil?
  end

  it 'wont load a string' do
    fetcher.resolve(rand.to_s).must_be :nil?
  end

  describe 'applied to a map' do
    it 'must be resolved' do
      fetcher.resolve({}).must_be_kind_of fetcher
    end

    it 'has no files on empty' do
      fetcher.resolve({}).files.must_equal []
    end

    it 'has files' do
      f = rand.to_s
      fetcher.resolve({f => nil}).files.must_equal [f]
    end

    it 'can read a file' do
      f = rand.to_s
      s = rand.to_s
      fetcher.resolve({f => s}).read(f).must_equal s
    end
  end
end
