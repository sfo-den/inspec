# encoding: utf-8
# author: Nolan Davidson
# author: Christoph Hartmann

require 'helper'

describe 'Inspec::Resources::MssqlSession' do
  it 'verify default mssql_session configuration' do
    resource = load_resource('mssql_session', user: 'sa', password: 'yourStrong(!)Password')
    _(resource.user).must_equal 'sa'
    _(resource.password).must_equal 'yourStrong(!)Password'
    _(resource.host).must_equal 'localhost'
    _(resource.port).must_equal '1433'
  end

  it 'verify mssql_session configuration with custom hostname' do
    resource = load_resource('mssql_session', user: 'sa', password: 'yourStrong(!)Password', host: 'inspec.domain.tld')
    _(resource.user).must_equal 'sa'
    _(resource.password).must_equal 'yourStrong(!)Password'
    _(resource.host).must_equal 'inspec.domain.tld'
    _(resource.port).must_equal '1433'
  end

  it 'verify mssql_session configuration with custom instance' do
    resource = load_resource('mssql_session', user: 'sa', password: 'yourStrong(!)Password', instance: 'SQL2012INSPEC')
    _(resource.user).must_equal 'sa'
    _(resource.password).must_equal 'yourStrong(!)Password'
    _(resource.host).must_equal 'localhost'
    _(resource.port).must_equal '1433'
    _(resource.instance).must_equal 'SQL2012INSPEC'
  end

  it 'verify mssql_session configuration with custom sqlserver port and user in domain' do
    resource = load_resource('mssql_session', user: 'DOMAIN\sa', password: 'yourStrong(!)Password', host: 'localhost', port: '1533')
    _(resource.user).must_equal 'DOMAIN\sa'
    _(resource.password).must_equal 'yourStrong(!)Password'
    _(resource.host).must_equal 'localhost'
    _(resource.port).must_equal '1533'
  end

  it 'run a SQL query' do
    resource = load_resource('mssql_session', user: 'sa', password: 'yourStrong(!)Password', host: 'localhost')
    query = resource.query("SELECT SERVERPROPERTY('ProductVersion') as result")
    _(query.size).must_equal 1
    _(query.row(0).column('result').value).must_equal '14.0.600.250'
  end
end
