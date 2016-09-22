# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'utils/parser'
require 'utils/convert'
require 'utils/filter'

module Inspec::Resources
  # This file contains two resources, the `user` and `users` resource.
  # The `user` resource is optimized for requests that verify specific users
  # that you know upfront for testing. If you need to query all users or search
  # specific users with certain properties, use the `users` resource.
  module UserManagementSelector
    # select user provider based on the operating system
    # returns nil, if no user manager was found for the operating system
    def select_user_manager(os)
      if os.linux?
        LinuxUser.new(inspec)
      elsif os.windows?
        WindowsUser.new(inspec)
      elsif ['darwin'].include?(os[:family])
        DarwinUser.new(inspec)
      elsif ['freebsd'].include?(os[:family])
        FreeBSDUser.new(inspec)
      elsif ['aix'].include?(os[:family])
        AixUser.new(inspec)
      elsif os.solaris?
        SolarisUser.new(inspec)
      elsif ['hpux'].include?(os[:family])
        HpuxUser.new(inspec)
      end
    end
  end

  # The InSpec users resources looksup all local users available on a system.
  # TODO: the current version of the users resource will use eg. /etc/passwd
  # on Linux to parse all usernames. Therefore the resource may not return
  # users managed on other systems like LDAP/ActiveDirectory. Please open
  # a feature request at https://github.com/chef/inspec if you need that
  # functionality
  #
  # This resource allows complex filter mechanisms
  #
  # describe users.where(uid: 0).entries do
  #   it { should eq ['root'] }
  #   its('uids') { should eq [1234] }
  #   its('gids') { should eq [1234] }
  # end
  #
  # describe users.where { uid =~ /S\-1\-5\-21\-\d+\-\d+\-\d+\-500/ } do
  #   it { should exist }
  # end
  class Users < Inspec.resource(1)
    include UserManagementSelector

    name 'users'
    desc 'Use the users InSpec audit resource to test local user profiles. Users can be filtered by groups to which they belong, the frequency of required password changes, the directory paths to home and shell.'
    example "
      describe users.where(uid: 0).entries do
        it { should eq ['root'] }
        its('uids') { should eq [1234] }
        its('gids') { should eq [1234] }
      end
    "
    def initialize
      # select user provider
      @user_provider = select_user_manager(inspec.os)
      return skip_resource 'The `users` resource is not supported on your OS yet.' if @user_provider.nil?
    end

    filter = FilterTable.create
    filter.add_accessor(:where)
          .add_accessor(:entries)
          .add(:usernames, field: :username)
          .add(:uids,      field: :uid)
          .add(:gids,      field: :gid)
          .add(:groupnames, field: :groupname)
          .add(:groups,    field: :groups)
          .add(:homes,     field: :home)
          .add(:shells,    field: :shell)
          .add(:mindays,   field: :mindays)
          .add(:maxdays,   field: :maxdays)
          .add(:warndays,  field: :warndays)
          .add(:disabled,  field: :disabled)
          .add(:exists?) { |x| !x.entries.empty? }
          .add(:disabled?) { |x| x.where { disabled == false }.entries.empty? }
          .add(:enabled?) { |x| x.where { disabled == true }.entries.empty? }
    filter.connect(self, :collect_user_details)

    def to_s
      'Users'
    end

    private

    # method to get all available users
    def list_users
      @username_cache ||= @user_provider.list_users unless @user_provider.nil?
    end

    # collects information about every user
    def collect_user_details
      @users_cache ||= @user_provider.collect_user_details unless @user_provider.nil?
    end
  end

  # The `user` resource handles the special case where only one resource is required
  #
  # describe user('root') do
  #   it { should exist }
  #   its('uid') { should eq 0 }
  #   its('gid') { should eq 0 }
  #   its('group') { should eq 'root' }
  #   its('groups') { should eq ['root', 'wheel']}
  #   its('home') { should eq '/root' }
  #   its('shell') { should eq '/bin/bash' }
  #   its('mindays') { should eq 0 }
  #   its('maxdays') { should eq 99 }
  #   its('warndays') { should eq 5 }
  # end
  #
  # The following  Serverspec  matchers are deprecated in favor for direct value access
  #
  # describe user('root') do
  #   it { should belong_to_group 'root' }
  #   it { should have_uid 0 }
  #   it { should have_home_directory '/root' }
  #   it { should have_login_shell '/bin/bash' }
  #   its('minimum_days_between_password_change') { should eq 0 }
  #   its('maximum_days_between_password_change') { should eq 99 }
  # end
  #
  # ServerSpec tests that are not supported:
  #
  # describe user('root') do
  #   it { should have_authorized_key 'ssh-rsa ADg54...3434 user@example.local' }
  #   its(:encrypted_password) { should eq 1234 }
  # end
  class User < Inspec.resource(1)
    include UserManagementSelector
    name 'user'
    desc 'Use the user InSpec audit resource to test user profiles, including the groups to which they belong, the frequency of required password changes, the directory paths to home and shell.'
    example "
      describe user('root') do
        it { should exist }
        its('uid') { should eq 1234 }
        its('gid') { should eq 1234 }
      end
    "
    def initialize(username = nil)
      @username = username
      # select user provider
      @user_provider = select_user_manager(inspec.os)
      return skip_resource 'The `user` resource is not supported on your OS yet.' if @user_provider.nil?
    end

    def exists?
      !identity.nil? && !identity[:username].nil?
    end

    def disabled?
      identity[:disabled] == true unless identity.nil?
    end

    def enabled?
      identity[:disabled] == false unless identity.nil?
    end

    def username
      identity[:username] unless identity.nil?
    end

    def uid
      identity[:uid] unless identity.nil?
    end

    def gid
      identity[:gid] unless identity.nil?
    end

    def groupname
      identity[:groupname] unless identity.nil?
    end
    alias group groupname

    def groups
      identity[:groups] unless identity.nil?
    end

    def home
      meta_info[:home] unless meta_info.nil?
    end

    def shell
      meta_info[:shell] unless meta_info.nil?
    end

    # returns the minimum days between password changes
    def mindays
      credentials[:mindays] unless credentials.nil?
    end

    # returns the maximum days between password changes
    def maxdays
      credentials[:maxdays] unless credentials.nil?
    end

    # returns the days for password change warning
    def warndays
      credentials[:warndays] unless credentials.nil?
    end

    # implement 'mindays' method to be compatible with serverspec
    def minimum_days_between_password_change
      deprecated('minimum_days_between_password_change', "Please use: its('mindays')")
      mindays
    end

    # implement 'maxdays' method to be compatible with serverspec
    def maximum_days_between_password_change
      deprecated('maximum_days_between_password_change', "Please use: its('maxdays')")
      maxdays
    end

    # implements rspec has matcher, to be compatible with serverspec
    # @see: https://github.com/rspec/rspec-expectations/blob/master/lib/rspec/matchers/built_in/has.rb
    def has_uid?(compare_uid)
      deprecated('has_uid?')
      uid == compare_uid
    end

    def has_home_directory?(compare_home)
      deprecated('has_home_directory?', "Please use: its('home')")
      home == compare_home
    end

    def has_login_shell?(compare_shell)
      deprecated('has_login_shell?', "Please use: its('shell')")
      shell == compare_shell
    end

    def has_authorized_key?(_compare_key)
      deprecated('has_authorized_key?')
      fail NotImplementedError
    end

    def deprecated(name, alternative = nil)
      warn "[DEPRECATION] #{name} is deprecated. #{alternative}"
    end

    def to_s
      "User #{@username}"
    end

    private

    # returns the iden
    def identity
      return @id_cache if defined?(@id_cache)
      @id_cache = @user_provider.identity(@username) if !@user_provider.nil?
    end

    def meta_info
      return @meta_cache if defined?(@meta_cache)
      @meta_cache = @user_provider.meta_info(@username) if !@user_provider.nil?
    end

    def credentials
      return @cred_cache if defined?(@cred_cache)
      @cred_cache = @user_provider.credentials(@username) if !@user_provider.nil?
    end
  end

  # This is an abstract class that every user provoider has to implement.
  # A user provider implements a system abstracts and helps the InSpec resource
  # hand-over system specific behavior to those providers
  class UserInfo
    include Converter

    attr_reader :inspec
    def initialize(inspec)
      @inspec = inspec
    end

    # returns a hash with user-specific values:
    # {
    #   uid: '',
    #   user: '',
    #   gid: '',
    #   group: '',
    #   groups: '',
    # }
    def identity(_username)
      fail 'user provider must implement the `identity` method'
    end

    # returns optional information about a user, eg shell
    def meta_info(_username)
      nil
    end

    # returns a hash with meta-data about user credentials
    # {
    #   mindays: 1,
    #   maxdays: 1,
    #   warndays: 1,
    # }
    # this method is optional and may not be implemented by each provider
    def credentials(_username)
      nil
    end

    # returns an array with users
    def list_users
      fail 'user provider must implement the `list_users` method'
    end

    # retuns all aspects of the user as one hash
    def user_details(username)
      item = {}
      id = identity(username)
      item.merge!(id) unless id.nil?
      meta = meta_info(username)
      item.merge!(meta) unless meta.nil?
      cred = credentials(username)
      item.merge!(cred) unless cred.nil?
      item
    end

    # returns the full information list for a user
    def collect_user_details
      list_users.map { |username|
        user_details(username.chomp)
      }
    end
  end

  # implements generic unix id handling
  class UnixUser < UserInfo
    attr_reader :inspec, :id_cmd, :list_users_cmd
    def initialize(inspec)
      @inspec = inspec
      @id_cmd ||= 'id'
      @list_users_cmd ||= 'cut -d: -f1 /etc/passwd | grep -v "^#"'
      super
    end

    # returns a list of all local users on a system
    def list_users
      cmd = inspec.command(list_users_cmd)
      return [] if cmd.exit_status != 0
      cmd.stdout.chomp.lines
    end

    # parse one id entry like '0(wheel)''
    def parse_value(line)
      SimpleConfig.new(
        line,
        line_separator: ',',
        assignment_re: /^\s*([^\(]*?)\s*\(\s*(.*?)\)*$/,
        group_re: nil,
        multiple_values: false,
      ).params
    end

    # extracts the identity
    def identity(username)
      cmd = inspec.command("#{id_cmd} #{username}")
      return nil if cmd.exit_status != 0

      # parse words
      params = SimpleConfig.new(
        parse_id_entries(cmd.stdout.chomp),
        assignment_re: /^\s*([^=]*?)\s*=\s*(.*?)\s*$/,
        group_re: nil,
        multiple_values: false,
      ).params

      {
        uid: convert_to_i(parse_value(params['uid']).keys[0]),
        username: parse_value(params['uid']).values[0],
        gid: convert_to_i(parse_value(params['gid']).keys[0]),
        groupname: parse_value(params['gid']).values[0],
        groups: parse_value(params['groups']).values,
      }
    end

    # splits the results of id into seperate lines
    def parse_id_entries(raw)
      data = []
      until (index = raw.index(/\)\s{1}/)).nil?
        data.push(raw[0, index+1]) # inclue closing )
        raw = raw[index+2, raw.length-index-2]
      end
      data.push(raw) if !raw.nil?
      data.join("\n")
    end
  end

  class LinuxUser < UnixUser
    include PasswdParser
    include CommentParser

    def meta_info(username)
      cmd = inspec.command("getent passwd #{username}")
      return nil if cmd.exit_status != 0
      # returns: root:x:0:0:root:/root:/bin/bash
      passwd = parse_passwd_line(cmd.stdout.chomp)
      {
        home: passwd['home'],
        shell: passwd['shell'],
      }
    end

    def credentials(username)
      cmd = inspec.command("chage -l #{username}")
      return nil if cmd.exit_status != 0

      params = SimpleConfig.new(
        cmd.stdout.chomp,
        assignment_re: /^\s*([^:]*?)\s*:\s*(.*?)\s*$/,
        group_re: nil,
        multiple_values: false,
      ).params

      {
        mindays: convert_to_i(params['Minimum number of days between password change']),
        maxdays: convert_to_i(params['Maximum number of days between password change']),
        warndays: convert_to_i(params['Number of days of warning before password expires']),
      }
    end
  end

  class SolarisUser < LinuxUser
    def initialize(inspec)
      @inspec = inspec
      @id_cmd ||= 'id -a'
      super
    end
  end

  class AixUser < UnixUser
    def identity(username)
      id = super(username)
      return nil if id.nil?
      # AIX 'id' command doesn't include the primary group in the supplementary
      # yet it can be somewhere in the supplementary list if someone added root
      # to a groups list in /etc/group
      # we rearrange to expected list if that is the case
      if id[:groups].first != id[:group]
        id[:groups].reject! { |i| i == id[:group] } if id[:groups].include?(id[:group])
        id[:groups].unshift(id[:group])
      end

      id
    end

    def meta_info(username)
      lsuser = inspec.command("lsuser -C -a home shell #{username}")
      return nil if lsuser.exit_status != 0

      user = lsuser.stdout.chomp.split("\n").last.split(':')
      {
        home:  user[1],
        shell: user[2],
      }
    end

    def credentials(username)
      cmd = inspec.command(
        "lssec -c -f /etc/security/user -s #{username} -a minage -a maxage -a pwdwarntime",
      )
      return nil if cmd.exit_status != 0

      user_sec = cmd.stdout.chomp.split("\n").last.split(':')

      {
        mindays:  user_sec[1].to_i * 7,
        maxdays:  user_sec[2].to_i * 7,
        warndays: user_sec[3].to_i,
      }
    end
  end

  class HpuxUser < UnixUser
    def meta_info(username)
      hpuxuser = inspec.command("logins -x -l #{username}")
      return nil if hpuxuser.exit_status != 0
      user = hpuxuser.stdout.chomp.split(' ')
      {
        home: user[4],
        shell: user[5],
      }
    end
  end

  # we do not use 'finger' for MacOS, because it is harder to parse data with it
  # @see https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/fingerd.8.html
  # instead we use 'dscl' to request user data
  # @see https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/dscl.1.html
  # @see http://superuser.com/questions/592921/mac-osx-users-vs-dscl-command-to-list-user
  class DarwinUser < UnixUser
    def initialize(inspec)
      @list_users_cmd ||= 'dscl . list /Users'
      super
    end

    def meta_info(username)
      cmd = inspec.command("dscl -q . -read /Users/#{username} NFSHomeDirectory PrimaryGroupID RecordName UniqueID UserShell")
      return nil if cmd.exit_status != 0

      params = SimpleConfig.new(
        cmd.stdout.chomp,
        assignment_re: /^\s*([^:]*?)\s*:\s*(.*?)\s*$/,
        group_re: nil,
        multiple_values: false,
      ).params

      {
        home: params['NFSHomeDirectory'],
        shell: params['UserShell'],
      }
    end
  end

  # FreeBSD recommends to use the 'pw' command for user management
  # @see: https://www.freebsd.org/doc/handbook/users-synopsis.html
  # @see: https://www.freebsd.org/cgi/man.cgi?pw(8)
  # It offers the following commands:
  # - adduser(8)	The recommended command-line application for adding new users.
  # - rmuser(8)	The recommended command-line application for removing users.
  # - chpass(1)	A flexible tool for changing user database information.
  # - passwd(1)	The command-line tool to change user passwords.
  class FreeBSDUser < UnixUser
    include PasswdParser

    def meta_info(username)
      cmd = inspec.command("pw usershow #{username} -7")
      return nil if cmd.exit_status != 0
      # returns: root:*:0:0:Charlie &:/root:/bin/csh
      passwd = parse_passwd_line(cmd.stdout.chomp)
      {
        home: passwd['home'],
        shell: passwd['shell'],
      }
    end
  end

  # For now, we stick with WMI Win32_UserAccount
  # @see https://msdn.microsoft.com/en-us/library/aa394507(v=vs.85).aspx
  # @see https://msdn.microsoft.com/en-us/library/aa394153(v=vs.85).aspx
  #
  # using Get-AdUser would be the best command for domain machines, but it will not be installed
  # on client machines by default
  # @see https://technet.microsoft.com/en-us/library/ee617241.aspx
  # @see https://technet.microsoft.com/en-us/library/hh509016(v=WS.10).aspx
  # @see http://woshub.com/get-aduser-getting-active-directory-users-data-via-powershell/
  # @see http://stackoverflow.com/questions/17548523/the-term-get-aduser-is-not-recognized-as-the-name-of-a-cmdlet
  #
  # Just for reference, we could also use ADSI (Active Directory Service Interfaces)
  # @see https://mcpmag.com/articles/2015/04/15/reporting-on-local-accounts.aspx
  class WindowsUser < UserInfo
    # parse windows account name
    def parse_windows_account(username)
      account = username.split('\\')
      name = account.pop
      domain = account.pop if account.size > 0
      [name, domain]
    end

    def identity(username)
      # extract domain/user information
      account, domain = parse_windows_account(username)

      # TODO: escape content
      if !domain.nil?
        filter = "Name = '#{account}' and Domain = '#{domain}'"
      else
        filter = "Name = '#{account}' and LocalAccount = true"
      end

      script = <<-EOH
        # find user
        $user = Get-WmiObject Win32_UserAccount -filter "#{filter}"
        # get related groups
        $groups = $user.GetRelated('Win32_Group') | Select-Object -Property Caption, Domain, Name, LocalAccount, SID, SIDType, Status
        # filter user information
        $user = $user | Select-Object -Property Caption, Description, Domain, Name, LocalAccount, Lockout, PasswordChangeable, PasswordExpires, PasswordRequired, SID, SIDType, Status, Disabled
        # build response object
        New-Object -Type PSObject | `
        Add-Member -MemberType NoteProperty -Name User -Value ($user) -PassThru | `
        Add-Member -MemberType NoteProperty -Name Groups -Value ($groups) -PassThru | `
        ConvertTo-Json
      EOH

      cmd = inspec.powershell(script)

      # cannot rely on exit code for now, successful command returns exit code 1
      # return nil if cmd.exit_status != 0, try to parse json
      begin
        params = JSON.parse(cmd.stdout)
      rescue JSON::ParserError => _e
        return nil
      end

      user_hash = params['User'] || {}
      group_hashes = params['Groups'] || []
      # if groups is no array, generate one
      group_hashes = [group_hashes] unless group_hashes.is_a?(Array)
      group_names = group_hashes.map { |grp| grp['Caption'] }
      {
        uid: user_hash['SID'],
        username: user_hash['Caption'],
        gid: nil,
        group: nil,
        groups: group_names,
        disabled: user_hash['Disabled'],
      }
    end

    # not implemented yet
    def meta_info(_username)
      {
        home: nil,
        shell: nil,
      }
    end

    def list_users
      script = 'Get-WmiObject Win32_UserAccount | Select-Object -ExpandProperty Caption'
      cmd = inspec.powershell(script)
      cmd.stdout.chomp.lines
    end
  end
end
