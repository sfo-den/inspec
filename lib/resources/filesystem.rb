module Inspec::Resources
  class FileSystemResource < Inspec.resource(1)
    name 'filesystem'
    supports platform: 'linux'
    supports platform: 'windows'
    desc 'Use the filesystem InSpec resource to test file system'
    example "
      describe filesystem('/') do
        its('size') { should be >= 32000 }
        its('type') { should eq false }
      end
      describe filesystem('c:') do
        its('size') { should be >= 90 }
        its('type') { should eq 'NTFS' }
      end
    "
    attr_reader :partition

    def initialize(partition)
      @partition = partition
      @cache = nil
      # select file system manager
      @fsman = nil

      os = inspec.os
      if os.linux?
        @fsman = LinuxFileSystemResource.new(inspec)
      elsif os.windows?
        @fsman = WindowsFileSystemResource.new(inspec)
      else
        raise Inspec::Exceptions::ResourceSkipped, 'The `filesystem` resource is not supported on your OS yet.'
      end
    end

    def info
      return @cache if !@cache.nil?
      return {} if @fsman.nil?
      @cache = @fsman.info(@partition)
    end

    def to_s
      "FileSystem #{@partition}"
    end

    def size
      info = @fsman.info(@partition)
      info[:size]
    end

    def type
      info = @fsman.info(@partition)
      info[:type]
    end

    def name
      info = @fsman.info(@partition)
      info[:name]
    end
  end

  class FsManagement
    attr_reader :inspec
    def initialize(inspec)
      @inspec = inspec
    end
  end

  class LinuxFileSystemResource < FsManagement
    def info(partition)
      cmd = inspec.command("df #{partition} --output=size")
      raise Inspec::Exceptions::ResourceFailed, "Unable to get available space for partition #{partition}" if cmd.stdout.nil? || cmd.stdout.empty? || !cmd.exit_status.zero?
      value = cmd.stdout.gsub(/\dK-blocks[\r\n]/, '').strip
      {
        name: partition,
        size: value.to_i,
        type: false,
      }
    end
  end

  class WindowsFileSystemResource < FsManagement
    def info(partition)
      cmd = inspec.command <<-EOF.gsub(/^\s*/, '')
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='#{partition}'"
        $disk.Size = $disk.Size / 1GB
        $disk | select -property DeviceID,Size,FileSystem | ConvertTo-Json
      EOF

      raise Inspec::Exceptions::ResourceSkipped, "Unable to get available space for partition #{partition}" if cmd.stdout == '' || cmd.exit_status.to_i != 0
      begin
        fs = JSON.parse(cmd.stdout)
      rescue JSON::ParserError => e
        raise Inspec::Exceptions::ResourceFailed,
              'Failed to parse JSON from Powershell. ' \
              "Error: #{e}"
      end
      {
        name: fs['DeviceID'],
        size: fs['Size'].to_i,
        type: fs['FileSystem'],
      }
    end
  end
end
