# encoding: utf-8
# author: Christoph Hartmann
#
# installs ssh
return if node['platform_family'] == 'windows'

include_recipe 'ssh-hardening::default'
