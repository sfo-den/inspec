# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'

describe 'Inspec::Resources::MysqlConf' do
  it 'verify mysql.conf config parsing' do
    resource = load_resource('mysql_conf', '/etc/mysql/my.cnf')
    _(resource.client['port']).must_equal '3306'
    _(resource.mysqld['user']).must_equal 'mysql'
    _(resource.mysqld['key_buffer_size']).must_equal '16M'
  end
end
