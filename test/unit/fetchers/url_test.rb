# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann
require 'helper'

describe Fetchers::Url do
  it 'registers with the fetchers registry' do
    reg = Inspec::Fetcher.registry
    _(reg['url']).must_equal Fetchers::Url
  end

  describe 'testing different urls' do
    # We don't use the MockLoader here becuase it produces tarballs
    # with different sha's on each run
    let(:expected_shasum) { "98b1ae45059b004178a8eee0c1f6179dcea139c0fd8a69ee47a6f02d97af1f17" }
    let(:mock_open) {
      m = Minitest::Mock.new
      m.expect :meta, {'content-type' => 'application/gzip'}
      m.expect :read, "fake content"
      m
    }

    it 'handles a http url' do
      url = 'http://chef.io/some.tar.gz'
      res = Fetchers::Url.resolve(url)
      res.expects(:open).returns(mock_open)
      _(res).must_be_kind_of Fetchers::Url
      _(res.resolved_source).must_equal({url: 'http://chef.io/some.tar.gz', sha256: expected_shasum})
    end

    it 'handles a https url' do
      url = 'https://chef.io/some.tar.gz'
      res = Fetchers::Url.resolve(url)
      res.expects(:open).returns(mock_open)
      _(res).must_be_kind_of Fetchers::Url
      _(res.resolved_source).must_equal({url: 'https://chef.io/some.tar.gz', sha256: expected_shasum})

    end

    it 'doesnt handle other schemas' do
      Fetchers::Url.resolve('gopher://chef.io/some.tar.gz').must_be_nil
    end

    it 'only handles URLs' do
      Fetchers::Url.resolve(__FILE__).must_be_nil
    end

    %w{https://github.com/chef/inspec
       https://github.com/chef/inspec.git
       https://www.github.com/chef/inspec.git
       http://github.com/chef/inspec
       http://github.com/chef/inspec.git
       http://www.github.com/chef/inspec.git}.each do |github|
      it "resolves a github url #{github}" do
        res = Fetchers::Url.resolve(github)
        res.expects(:open).returns(mock_open)
        _(res).wont_be_nil
        _(res.resolved_source).must_equal({url: 'https://github.com/chef/inspec/archive/master.tar.gz', sha256: expected_shasum})
      end
    end

    it "resolves a github branch url" do
      github = 'https://github.com/hardening-io/tests-os-hardening/tree/2.0'
      res = Fetchers::Url.resolve(github)
      res.expects(:open).returns(mock_open)
      _(res).wont_be_nil
      _(res.resolved_source).must_equal({url: 'https://github.com/hardening-io/tests-os-hardening/archive/2.0.tar.gz', sha256: expected_shasum})
    end

    it "resolves a github commit url" do
      github = 'https://github.com/hardening-io/tests-os-hardening/tree/48bd4388ddffde68badd83aefa654e7af3231876'
      res = Fetchers::Url.resolve(github)
      res.expects(:open).returns(mock_open)
      _(res).wont_be_nil
      _(res.resolved_source).must_equal({url: 'https://github.com/hardening-io/tests-os-hardening/archive/48bd4388ddffde68badd83aefa654e7af3231876.tar.gz',
                                         sha256: expected_shasum})
    end

    %w{https://bitbucket.org/chef/inspec
       https://bitbucket.org/chef/inspec.git
       https://www.bitbucket.org/chef/inspec.git
       http://bitbucket.org/chef/inspec
       http://bitbucket.org/chef/inspec.git
       http://www.bitbucket.org/chef/inspec.git}.each do |bitbucket|
      it "resolves a bitbucket url #{bitbucket}" do
        res = Fetchers::Url.resolve(bitbucket)
        res.expects(:open).returns(mock_open)
        _(res).wont_be_nil
        _(res.resolved_source).must_equal({url: 'https://bitbucket.org/chef/inspec/get/master.tar.gz', sha256: expected_shasum})
      end
    end

    it "resolves a bitbucket branch url" do
      bitbucket = 'https://bitbucket.org/chef/inspec/branch/newbranch'
      res = Fetchers::Url.resolve(bitbucket)
      res.expects(:open).returns(mock_open)
      _(res).wont_be_nil
      _(res.resolved_source).must_equal({url: 'https://bitbucket.org/chef/inspec/get/newbranch.tar.gz', sha256: expected_shasum})
    end

    it "resolves a bitbucket commit url" do
      bitbucket = 'https://bitbucket.org/chef/inspec/commits/48bd4388ddffde68badd83aefa654e7af3231876'
      res = Fetchers::Url.resolve(bitbucket)
      res.expects(:open).returns(mock_open)
      _(res).wont_be_nil
      _(res.resolved_source).must_equal({url: 'https://bitbucket.org/chef/inspec/get/48bd4388ddffde68badd83aefa654e7af3231876.tar.gz', sha256: expected_shasum})
    end

  end

  describe 'applied to a valid url (mocked tar.gz)' do
    let(:mock_file) { MockLoader.profile_tgz('complete-profile') }
    let(:target) { 'http://myurl/file.tar.gz' }
    let(:subject) { Fetchers::Url.resolve(target) }
    let(:mock_open) {
      m = Minitest::Mock.new
      m.expect :meta, {'content-type' => 'application/gzip'}
      m.expect :read, File.open(mock_file, 'rb').read
      m
    }

    let(:mock_dest) {
      f = Tempfile.new("url-fetch-test")
      f.path
    }

    it 'tries to fetch the file' do
      subject.expects(:open).returns(mock_open)
      subject.fetch(mock_dest)
    end

    it "returns the resolved_source hash" do
      subject.expects(:open).returns(mock_open)
      subject.resolved_source[:url].must_equal(target)
    end
  end
end
