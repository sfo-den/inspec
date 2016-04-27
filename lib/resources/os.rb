# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

module Inspec::Resources
  class OSResource < Inspec.resource(1)
    name 'os'
    desc 'Use the os InSpec audit resource to test the platform on which the system is running.'
    example "
      describe os[:family] do
        it { should eq 'redhat' }
      end
    "

    # reuse helper methods from backend
    %w{aix? redhat? debian? suse? bsd? solaris? linux? unix? windows? hpux?}.each do |os_family|
      define_method(os_family.to_sym) do
        inspec.backend.os.send(os_family)
      end
    end

    def [](name)
      # convert string to symbol
      name = name.to_sym if name.is_a? String
      inspec.backend.os[name]
    end

    def params
      {
        name: inspec.backend.os[:name],
        family: inspec.backend.os[:family],
        release: inspec.backend.os[:release],
        arch: inspec.backend.os[:arch],
      }
    end

    def to_s
      'Operating System Detection'
    end
  end
end
