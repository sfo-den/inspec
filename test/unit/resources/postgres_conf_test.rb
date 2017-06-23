# encoding: utf-8
# author: Aaron Lippold

require 'helper'

describe 'Inspec::Resources::Postgres' do
  it 'verify postgresql.conf config parsing of a simple key value' do
    resource = load_resource('postgres_conf', '/etc/postgresql/9.4/main/postgresql.conf')
    _(resource.params('log_connections')).must_equal 'on'
  end
  it 'verify postgresql.conf config parsing of a complex key value' do
    resource = load_resource('postgres_conf', '/etc/postgresql/9.4/main/postgresql.conf')
    _(resource.value(['pgaudit.log_parameter'])).must_equal 'on'
  end
end
