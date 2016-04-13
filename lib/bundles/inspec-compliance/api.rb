# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'net/http'
require 'uri'

module Compliance
  # API Implementation does not hold any state by itself,
  # everything will be stored in local Configuration store
  class API
    # login method for pre-1.0 compliance server
    def self.legacy_login_post(url, username, password, insecure)
      # form request
      # TODO: reuse post function
      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri.path)
      req.basic_auth(username, password)
      req.form_data={}

      send_request(uri, req, insecure)
    end

    # return all compliance profiles available for the user
    def self.profiles(config)
      url = "#{config['server']}/user/compliance"
      # TODO, api should not be dependent on .supported?
      response = Compliance::HTTP.get(url, config['token'], config['insecure'], !config.supported?(:oidc))
      data = response.body
      if !data.nil?
        profiles = JSON.parse(data)
        # iterate over profiles
        profiles.map do |owner, ps|
          ps.keys.map do |name|
            { org: owner, name: name }
          end
        end.flatten
      else
        []
      end
    end

    # return the server api version
    # NB this method does not use Compliance::Configuration to allow for using
    # it before we know the version (e.g. oidc or not)
    def self.version(url, insecure)
      response = Compliance::HTTP.get(url+'/version', nil, insecure)
      data = response.body
      if !data.nil?
        JSON.parse(data)
      else
        {}
      end
    end

    # verifies that a profile
    def self.exist?(config, profile)
      profiles = Compliance::API.profiles(config)
      if !profiles.empty?
        index = profiles.index { |p| "#{p[:org]}/#{p[:name]}" == profile }
        !index.nil? && index >= 0
      else
        false
      end
    end

    def self.upload(config, owner, profile_name, archive_path)
      # upload the tar to Chef Compliance
      url = "#{config['server']}/owners/#{owner}/compliance/#{profile_name}/tar"
      res = Compliance::HTTP.post_file(url, config['token'], archive_path, config['insecure'], !config.supported?(:oidc))
      [res.is_a?(Net::HTTPSuccess), res.body]
    end

    def self.post_refresh_token(url, token, insecure)
      uri = URI.parse("#{url}/login")
      req = Net::HTTP::Post.new(uri.path)
      # req['Authorization'] = "Bearer #{token}"
      req.body = { token: token }.to_json
      access_token = nil
      response = Compliance::HTTP.send_request(uri, req, insecure)
      data = response.body
      if !data.nil?
        begin
          tokendata = JSON.parse(data)
          access_token = tokendata['access_token']
          msg = 'Successfully fetched access token'
          success = true
        rescue JSON::ParserError => e
          success = false
          msg = e.message
        end
      else
        success = false
        msg = 'Invalid refresh_token'
      end

      [success, msg, access_token]
    end
  end
end
