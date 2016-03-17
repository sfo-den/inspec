# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

module Fetchers
  class Mock < Inspec.fetcher(1)
    name 'mock'
    priority 0

    def self.resolve(target)
      return nil unless target.is_a? Hash
      new(target)
    end

    def initialize(data)
      @data = data
    end

    def files
      @data.keys
    end

    def read(file)
      @data[file]
    end
  end
end
