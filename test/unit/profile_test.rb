# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/profile_context'
require 'inspec/runner'
require 'inspec/runner_mock'

describe Inspec::Profile do
  let(:logger) { Minitest::Mock.new }
  let(:home) { File.dirname(__FILE__) }

  def load_profile(name, opts = {})
    opts[:test_collector] = Inspec::RunnerMock.new
    Inspec::Profile.from_path("#{home}/mock/profiles/#{name}", opts)
  end

  describe 'with empty profile (legacy mode)' do
    let(:profile) { load_profile('legacy-empty-metadata') }

    it 'has no metadata' do
      profile.params[:name].must_be_nil
    end

    it 'has no rules' do
      profile.params[:rules].must_equal({})
    end
  end

  describe 'with normal metadata in profile (legacy mode)' do
    let(:profile) { load_profile('legacy-metadata') }

    it 'has metadata' do
      profile.params[:name].must_equal 'metadata profile'
    end

    it 'has no rules' do
      profile.params[:rules].must_equal({})
    end
  end

  describe 'when checking' do
    describe 'an empty profile (legacy mode)' do
      let(:profile_id) { 'legacy-empty-metadata' }

      it 'prints loads of warnings' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :warn, nil, ['The use of `metadata.rb` is deprecated. Use `inspec.yml`.']
        logger.expect :error, nil, ['Missing profile name in metadata.rb']
        logger.expect :error, nil, ['Missing profile version in metadata.rb']
        logger.expect :warn, nil, ['Missing profile title in metadata.rb']
        logger.expect :warn, nil, ['Missing profile summary in metadata.rb']
        logger.expect :warn, nil, ['Missing profile maintainer in metadata.rb']
        logger.expect :warn, nil, ['Missing profile copyright in metadata.rb']
        logger.expect :warn, nil, ['No controls or tests were defined.']

        load_profile(profile_id, {logger: logger}).check
        logger.verify
      end
    end

    describe 'a complete metadata profile (legacy mode)' do
      let(:profile_id) { 'legacy-complete-metadata' }
      let(:profile) { load_profile(profile_id, {logger: logger}) }

      it 'prints ok messages' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :warn, nil, ['The use of `metadata.rb` is deprecated. Use `inspec.yml`.']
        logger.expect :info, nil, ['Metadata OK.']
        logger.expect :warn, nil, ["Profile uses deprecated `test` directory, rename it to `controls`."]
        logger.expect :warn, nil, ['No controls or tests were defined.']

        profile.check
        logger.verify
      end

      it 'doesnt have constraints on supported systems' do
        profile.metadata.params.wont_include(:supports)
      end
    end

    describe 'a complete metadata profile with controls' do
      let(:profile_id) { 'complete-profile' }

      it 'prints ok messages and counts the rules' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :info, nil, ['Metadata OK.']
        logger.expect :info, nil, ['Found 1 rules.']
        logger.expect :debug, nil, ["Verify all rules in  #{home}/mock/profiles/#{profile_id}/controls/filesystem_spec.rb"]
        logger.expect :info, nil, ['Rule definitions OK.']

        load_profile(profile_id, {logger: logger, ignore_supports: true}).check
        logger.verify
      end
    end
  end
end
