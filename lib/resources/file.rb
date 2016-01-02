# encoding: utf-8
# copyright: 2015, Vulcano Security GmbH
# author: Dominik Richter
# author: Christoph Hartmann
# license: All rights reserved

module Inspec::Resources
  class File < Inspec.resource(1)
    name 'file'
    desc 'Use the file InSpec audit resource to test all system file types, including files, directories, symbolic links, named pipes, sockets, character devices, block devices, and doors.'
    example "
      describe file('path') do
        it { should exist }
        it { should be_file }
        it { should be_readable }
        it { should be_writable }
        it { should be_owned_by 'root' }
        its('mode') { should eq 0644 }
      end
    "
    include MountParser

    attr_reader :file, :path, :mount_options
    def initialize(path)
      @path = path
      @file = inspec.backend.file(@path)
    end

    %w{
      type exist? file? block_device? character_device? socket? directory?
      symlink? pipe? mode mode? owner owned_by? group grouped_into? link_target
      link_path linked_to? content mtime size selinux_label immutable?
      product_version file_version version? md5sum sha256sum
    }.each do |m|
      define_method m.to_sym do |*args|
        file.method(m.to_sym).call(*args)
      end
    end

    def contain(*_)
      fail 'Contain is not supported. Please use standard RSpec matchers.'
    end

    def readable?(by_usergroup, by_specific_user)
      return false unless exist?

      file_permission_granted?('r', by_usergroup, by_specific_user)
    end

    def writable?(by_usergroup, by_specific_user)
      return false unless exist?

      file_permission_granted?('w', by_usergroup, by_specific_user)
    end

    def executable?(by_usergroup, by_specific_user)
      return false unless exist?

      file_permission_granted?('x', by_usergroup, by_specific_user)
    end

    def mounted?(expected_options = nil, identical = false)
      mounted = file.mounted

      # return if no additional parameters have been provided
      return file.mounted? if expected_options.nil?

      # parse content if we are on linux
      @mount_options ||= parse_mount_options(mounted.stdout, true)

      if identical
        # check if the options should be identical
        @mount_options == expected_options
      else
        # otherwise compare the selected values
        @mount_options.contains(expected_options)
      end
    end

    def to_s
      "File #{path}"
    end

    private

    def file_permission_granted?(flag, by_usergroup, by_specific_user)
      fail 'Checking file permissions is not supported on your os' unless unix?

      usergroup = usergroup_for(by_usergroup, by_specific_user)

      if by_specific_user.nil?
        check_file_permission_by_mask(usergroup, flag)
      else
        check_file_permission_by_user(by_specific_user, flag)
      end
    end

    def check_file_permission_by_mask(usergroup, flag)
      mask = file.unix_mode_mask(usergroup, flag)
      fail 'Invalid usergroup/owner provided' if mask.nil?

      (file.mode & mask) != 0
    end

    def check_file_permission_by_user(user, flag)
      if linux?
        perm_cmd = "su -s /bin/sh -c \"test -#{flag} #{path}\" #{user}"
      elsif family == 'freebsd'
        perm_cmd = "sudo -u #{user} test -#{flag} #{path}"
      else
        return skip_resource 'The `file` resource does not support `by_user` on your OS.'
      end

      cmd = inspec.command(perm_cmd)
      cmd.exit_status == 0 ? true : false
    end

    def usergroup_for(usergroup, specific_user)
      if usergroup == 'others'
        'other'
      elsif (usergroup.nil? || usergroup.empty?) && specific_user.nil?
        'all'
      else
        usergroup
      end
    end

    def unix?
      inspec.os.unix?
    end

    def linux?
      inspec.os.linux?
    end

    def family
      inspec.os[:family]
    end
  end
end
