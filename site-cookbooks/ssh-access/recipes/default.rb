access = EncryptedDataBagItem.load('ssh-access',
                                   node['ssh-access-databag']).to_hash

user 'root' do
  action :lock
end

user 'deploy' do
  action :create
  password access['deploy_sudo_password']
  home '/home/deploy'
  shell '/bin/bash'
  supports :manage_home => true
end

group 'sudo' do
  action :modify
  append true
  members 'deploy'
end

directory '/home/deploy/.ssh' do
  action :create
  owner 'deploy'
  group 'deploy'
  mode 00744
end

file '/home/deploy/.ssh/authorized_keys' do
  owner 'deploy'
  group 'deploy'
  mode 00644
  content access['deploy_authorized_keys'].join('\r\n')
end

execute 'ufw --force reset'

firewall 'ufw' do
  action :enable
end

access['ssh_allowed_hosts'].each do |allowed_host|
  firewall_rule 'ssh' do
    port access['ssh_port'].to_i
    protocol :tcp
    source    allowed_host
    action :allow
  end
end

node.set['openssh']['server'] = {
  port: access['ssh_port'],
  password_authentication: 'no',
  permit_root_login: 'no'
}

include_recipe 'firewall'
include_recipe 'openssh'
include_recipe 'fail2ban'