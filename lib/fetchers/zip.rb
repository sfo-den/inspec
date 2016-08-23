# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'zip'

module Fetchers
  class Zip < Inspec.fetcher(1)
    name 'zip'
    priority 100

    attr_reader :files

    def self.resolve(target)
      unless target.is_a?(String) && File.file?(target) && target.end_with?('.zip')
        return nil
      end
      new(target)
    end

    def initialize(target)
      @target = target
      @contents = {}
      @files = []
      ::Zip::InputStream.open(@target) do |io|
        while (entry = io.get_next_entry)
          @files.push(entry.name.sub(%r{/+$}, ''))
        end
      end
    end

    def url
      if parent
        parent.url
      else
        'file://target'
      end
    end

    def read(file)
      @contents[file] ||= read_from_zip(file)
    end

    def read_from_zip(file)
      return nil unless @files.include?(file)
      res = nil
      ::Zip::InputStream.open(@target) do |io|
        while (entry = io.get_next_entry)
          next unless file == entry.name
          res = io.read
          break
        end
      end
      res
    end
  end
end
