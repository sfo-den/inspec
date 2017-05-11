# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/profile_context'

describe Inspec::Profile do
  let(:logger) { Minitest::Mock.new }
  let(:home) { MockLoader.home }

  describe 'with an empty profile' do
    let(:profile) { MockLoader.load_profile('empty-metadata') }

    it 'has a default name containing the original target' do
      profile.params[:name].must_match(/tests from .*empty-metadata/)
    end

    it 'has no controls' do
      profile.params[:controls].must_equal({})
    end
  end

  describe 'with an empty profile (legacy mode)' do
    let(:profile) { MockLoader.load_profile('legacy-empty-metadata') }

    it 'has a default name containing the original target' do
      profile.params[:name].must_match(/tests from .*empty-metadata/)
    end

    it 'has no controls' do
      profile.params[:controls].must_equal({})
    end
  end

  describe 'with simple metadata in profile' do
    let(:profile_id) { 'simple-metadata' }
    let(:profile) { MockLoader.load_profile(profile_id) }

    it 'has metadata' do
      profile.params[:name].must_equal 'yumyum profile'
    end

    it 'has no controls' do
      profile.params[:controls].must_equal({})
    end

    it 'can overwrite the profile ID' do
      testID = rand.to_s
      res = MockLoader.load_profile(profile_id, id: testID)
      res.params[:name].must_equal testID
    end
  end

  describe 'with simple metadata in profile (legacy mode)' do
    let(:profile) { MockLoader.load_profile('legacy-simple-metadata') }

    it 'has metadata' do
      profile.params[:name].must_equal 'metadata profile'
    end

    it 'has no controls' do
      profile.params[:controls].must_equal({})
    end
  end

  describe 'SHA256 sums' do
    it 'works on an empty profile' do
      MockLoader.load_profile('empty-metadata').sha256.must_equal 'ee95f4cf4258402604d4cc581a672bbd2f73d212b09cd4bcf1c5984e97e68963'
    end

    it 'works on a complete profile' do
      MockLoader.load_profile('complete-profile').sha256.must_equal '41ce15e61b7e02aad5dade183f68c547e062f1390762d266c5c8cf96d49134c7'
    end
  end

  describe 'when checking' do
    describe 'an empty profile' do
      let(:profile_id) { 'empty-metadata' }

      it 'prints loads of warnings' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :error, nil, ["Missing profile version in inspec.yml"]
        logger.expect :warn, nil, ["Missing profile title in inspec.yml"]
        logger.expect :warn, nil, ["Missing profile summary in inspec.yml"]
        logger.expect :warn, nil, ["Missing profile maintainer in inspec.yml"]
        logger.expect :warn, nil, ["Missing profile copyright in inspec.yml"]
        logger.expect :warn, nil, ['No controls or tests were defined.']

        result = MockLoader.load_profile(profile_id, {logger: logger}).check
        # verify logger output
        logger.verify

        # verify hash result
        result[:summary][:valid].must_equal false
        result[:summary][:location].must_equal "#{home}/mock/profiles/#{profile_id}"
        result[:summary][:profile].must_match(/tests from .*empty-metadata/)
        result[:summary][:controls].must_equal 0
        result[:errors].length.must_equal 1
        result[:warnings].length.must_equal 5
      end
    end

    describe 'an empty profile (legacy mode)' do
      let(:profile_id) { 'legacy-empty-metadata' }

      it 'prints loads of warnings' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :warn, nil, ['The use of `metadata.rb` is deprecated. Use `inspec.yml`.']
        logger.expect :error, nil, ["Missing profile version in metadata.rb"]
        logger.expect :warn, nil, ["Missing profile title in metadata.rb"]
        logger.expect :warn, nil, ["Missing profile summary in metadata.rb"]
        logger.expect :warn, nil, ["Missing profile maintainer in metadata.rb"]
        logger.expect :warn, nil, ["Missing profile copyright in metadata.rb"]
        logger.expect :warn, nil, ['No controls or tests were defined.']

        result = MockLoader.load_profile(profile_id, {logger: logger}).check
        # verify logger output
        logger.verify

        # verify hash result
        result[:summary][:valid].must_equal false
        result[:summary][:location].must_equal "#{home}/mock/profiles/#{profile_id}"
        result[:summary][:profile].must_match(/tests from .*legacy-empty-metadata/)
        result[:summary][:controls].must_equal 0
        result[:errors].length.must_equal 1
        result[:warnings].length.must_equal 6
      end
    end

    describe 'a complete metadata profile' do
      let(:profile_id) { 'complete-metadata' }
      let(:profile) { MockLoader.load_profile(profile_id, {logger: logger}) }

      it 'prints ok messages' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :info, nil, ['Metadata OK.']
        logger.expect :warn, nil, ['No controls or tests were defined.']

        result = profile.check

        # verify logger output
        logger.verify

        # verify hash result
        result[:summary][:valid].must_equal true
        result[:summary][:location].must_equal "#{home}/mock/profiles/#{profile_id}"
        result[:summary][:profile].must_equal 'name'
        result[:summary][:controls].must_equal 0
        result[:errors].length.must_equal 0
        result[:warnings].length.must_equal 1
      end
    end

    describe 'a complete metadata profile (legacy mode)' do
      let(:profile_id) { 'legacy-complete-metadata' }
      let(:profile) { MockLoader.load_profile(profile_id, {logger: logger}) }

      it 'prints ok messages' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :warn, nil, ['The use of `metadata.rb` is deprecated. Use `inspec.yml`.']
        logger.expect :info, nil, ['Metadata OK.']
        # NB we only look at content that is loaded, i.e., there're no empty directories anymore
        # logger.expect :warn, nil, ["Profile uses deprecated `test` directory, rename it to `controls`."]
        logger.expect :warn, nil, ['No controls or tests were defined.']

        result = profile.check

        # verify logger output
        logger.verify

        # verify hash result
        result[:summary][:valid].must_equal true
        result[:summary][:location].must_equal "#{home}/mock/profiles/#{profile_id}"
        result[:summary][:profile].must_equal 'name'
        result[:summary][:controls].must_equal 0
        result[:errors].length.must_equal 0
        result[:warnings].length.must_equal 2
      end

      it 'doesnt have constraints on supported systems' do
        profile.metadata.params[:supports].must_equal([])
      end
    end

    describe 'a complete metadata profile with controls' do
      let(:profile_id) { 'complete-profile' }

      it 'prints ok messages and counts the controls' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :info, nil, ['Metadata OK.']
        logger.expect :info, nil, ['Found 1 controls.']
        logger.expect :info, nil, ['Control definitions OK.']

        result = MockLoader.load_profile(profile_id, {logger: logger}).check
        # verify logger output
        logger.verify

        # verify hash result
        result[:summary][:valid].must_equal true
        result[:summary][:location].must_equal "#{home}/mock/profiles/#{profile_id}"
        result[:summary][:profile].must_equal 'complete'
        result[:summary][:controls].must_equal 1
        result[:errors].length.must_equal 0
        result[:warnings].length.must_equal 0
      end
    end

    describe 'a complete metadata profile with controls in a tarball' do
      let(:profile_id) { 'complete-profile' }
      let(:profile_path) { MockLoader.profile_tgz(profile_id) }
      let(:profile) { MockLoader.load_profile(profile_path, {logger: logger}) }

      it 'prints ok messages and counts the controls' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :info, nil, ['Metadata OK.']
        logger.expect :info, nil, ['Found 1 controls.']
        logger.expect :info, nil, ['Control definitions OK.']

        result = MockLoader.load_profile(profile_id, {logger: logger}).check
        # verify logger output
        logger.verify

        # verify hash result
        result[:summary][:valid].must_equal true
        result[:summary][:location].must_equal "#{home}/mock/profiles/#{profile_id}"
        result[:summary][:profile].must_equal 'complete'
        result[:summary][:controls].must_equal 1
        result[:errors].length.must_equal 0
        result[:warnings].length.must_equal 0
      end
    end

    describe 'a complete metadata profile with controls in zipfile' do
      let(:profile_id) { 'complete-profile' }
      let(:profile_path) { MockLoader.profile_zip(profile_id) }
      let(:profile) { MockLoader.load_profile(profile_path, {logger: logger}) }

      it 'prints ok messages and counts the controls' do
        logger.expect :info, nil, ["Checking profile in #{home}/mock/profiles/#{profile_id}"]
        logger.expect :info, nil, ['Metadata OK.']
        logger.expect :info, nil, ['Found 1 controls.']
        logger.expect :info, nil, ['Control definitions OK.']

        result = MockLoader.load_profile(profile_id, {logger: logger}).check
        # verify logger output
        logger.verify

        # verify hash result
        result[:summary][:valid].must_equal true
        result[:summary][:location].must_equal "#{home}/mock/profiles/#{profile_id}"
        result[:summary][:profile].must_equal 'complete'
        result[:summary][:controls].must_equal 1
        result[:errors].length.must_equal 0
        result[:warnings].length.must_equal 0
      end
    end
  end
end
