# encoding: utf-8
# author: Dominik Richter
#
# Helper recipe to create create a few files in the operating
# systems, which the runner will test against.
# It also initializes the runner inside the machines
# and makes sure all dependencies are ready to go.
#
# Finally (for now), it actually executes the all tests with
# the local execution backend

gid = 'root'
gid = 'wheel' if node['platform_family'] == 'freebsd'

file '/tmp/file' do
  mode '0765'
  owner 'root'
  group gid
  content 'hello world'
end

directory '/tmp/folder' do
  mode '0567'
  owner 'root'
  group gid
end

link '/tmp/symlink'do
  to '/tmp/file'
  owner 'root'
  group gid
  mode '0777'
end

execute 'create pipe/fifo' do
  command 'mkfifo /tmp/pipe'
  not_if 'test -e /tmp/pipe'
end

execute 'create block_device' do
  command "mknod /tmp/block_device b 7 7 && chmod 0666 /tmp/block_device && chown root:#{gid} /tmp/block_device"
  not_if 'test -e /tmp/block_device'
end

# prepare ssh for backend
execute 'create ssh key' do
  command 'ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N ""'
  not_if 'test -e /root/.ssh/id_rsa'
end

execute 'add ssh key to vagrant user' do
  command 'cat /root/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys'
end

execute 'test ssh connection' do
  command 'ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa vagrant@localhost "echo 1"'
end

# execute tests
execute 'bundle install' do
  command '/opt/chef/embedded/bin/bundle install'
  cwd '/tmp/kitchen/data'
end

execute 'run local tests' do
  command '/opt/chef/embedded/bin/ruby -I lib test/runner/test_local.rb test/runner/tests/*_test.rb'
  cwd '/tmp/kitchen/data'
end

execute 'run ssh tests' do
  command '/opt/chef/embedded/bin/ruby -I lib test/runner/test_ssh.rb test/runner/tests/*_test.rb'
  cwd '/tmp/kitchen/data'
end
