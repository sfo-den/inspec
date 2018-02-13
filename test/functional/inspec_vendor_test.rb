# encoding: utf-8
# author: Christoph Hartmann
require 'functional/helper'
require 'tmpdir'

describe 'example inheritance profile' do
  include FunctionalHelper
  let(:inheritance_path) { File.join(examples_path, 'inheritance') }
  let(:meta_path) { File.join(examples_path, 'meta-profile') }

  it 'can vendor profile dependencies' do
    prepare_examples('inheritance') do |dir|
      out = inspec('vendor ' + dir + ' --overwrite')
      out.stderr.must_equal ''
      out.stdout.must_include "Dependencies for profile #{dir} successfully vendored to #{dir}/vendor"
      out.exit_status.must_equal 0

      File.exist?(File.join(dir, 'vendor')).must_equal true
      File.exist?(File.join(dir, 'inspec.lock')).must_equal true
    end
  end

  it 'can vendor profile dependencies from the profile path' do
    prepare_examples('inheritance') do |dir|
      out = inspec('vendor --overwrite', "cd #{dir} &&")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
      # this fixes the osx /var symlink to /private/var causing this test to fail
      out.stdout.gsub!('/private/var', '/var')
      out.stdout.must_include "Dependencies for profile #{dir} successfully vendored to #{dir}/vendor"

      File.exist?(File.join(dir, 'vendor')).must_equal true
      File.exist?(File.join(dir, 'inspec.lock')).must_equal true
    end
  end

  it 'ensure nothing is loaded from external source if vendored profile is used' do
    prepare_examples('meta-profile') do |dir|
      out = inspec('vendor ' + dir + ' --overwrite')
      out.stderr.must_equal ''
      out.exit_status.must_equal 0

      File.exist?(File.join(dir, 'vendor')).must_equal true
      File.exist?(File.join(dir, 'inspec.lock')).must_equal true

      out = inspec('exec ' + dir + ' -l debug --no-create-lockfile')
      out.stderr.must_equal "[DEPRECATED] The use of inspec.yml `supports:inspec` is deprecated and will be removed in InSpec 2.0. Please use `inspec_version` instead.\n"
      out.stdout.must_include 'Using cached dependency for {:url=>"https://github.com/dev-sec/ssh-baseline/archive/master.tar.gz"'
      out.stdout.must_include 'Using cached dependency for {:url=>"https://github.com/dev-sec/ssl-baseline/archive/master.tar.gz"'
      out.stdout.must_include 'Using cached dependency for {:url=>"https://github.com/chris-rock/windows-patch-benchmark/archive/master.tar.gz"'
      out.stdout.wont_include 'Fetching URL:'
      out.stdout.wont_include 'Fetched archive moved to:'
    end
  end

  it 'ensure json/check command do not fetch remote profiles if vendored' do
    prepare_examples('meta-profile') do |dir|
      out = inspec('vendor ' + dir + ' --overwrite')
      out.stderr.must_equal ''
      out.exit_status.must_equal 0

      out = inspec('json ' + dir + ' --output ' + dst.path)
      out.exit_status.must_equal 0

      hm = JSON.load(File.read(dst.path))
      hm['name'].must_equal 'meta-profile'
      hm['controls'].length.must_be :>=, 78

      # out.stdout.scan(/Copy .* to cache directory/).length.must_equal 3
      # out.stdout.scan(/Dependency does not exist in the cache/).length.must_equal 1
      out.stdout.scan(/Fetching URL:/).length.must_equal 0

      # execute check command
      out = inspec('check ' + dir + ' -l debug')
      # stderr may have warnings included; only test if something went wrong
      out.stderr.must_equal('') if out.exit_status != 0
      out.exit_status.must_equal 0

      out.stdout.scan(/Fetching URL:/).length.must_equal 0
    end
  end

  it 'use lockfile in tarball' do
    prepare_examples('meta-profile') do |dir|
      # ensure the profile is vendored and packaged as tar
      out = inspec('vendor ' + dir + ' --overwrite')
      out = inspec('archive ' + dir + ' --overwrite')
      out.exit_status.must_equal 0

      # execute json command
      out = inspec('json meta-profile-0.2.0.tar.gz -l debug')
      # stderr may have warnings included; only test if something went wrong
      out.stderr.must_equal('') if out.exit_status != 0
      out.exit_status.must_equal 0

      out.stdout.scan(/Fetching URL:/).length.must_equal 0
    end
  end

  it 'can move vendor files into custom vendor cache' do
    prepare_examples('meta-profile') do |dir|
      out = inspec('vendor ' + dir + ' --overwrite')
      out.stderr.must_equal ''
      out.exit_status.must_equal 0

      File.exist?(File.join(dir, 'vendor')).must_equal true
      File.exist?(File.join(dir, 'inspec.lock')).must_equal true
      File.exist?(File.join(dir, 'vendor_cache')).must_equal false

      exec_out = inspec('exec ' + dir + ' --vendor-cache ' + dir + '/vendor_cache')

      File.exist?(File.join(dir, 'vendor_cache')).must_equal true
      vendor_files = Dir.entries("#{dir}/vendor/")
      vendor_cache_files = Dir.entries("#{dir}/vendor_cache/")
      vendor_files.must_equal vendor_cache_files
    end
  end
end
