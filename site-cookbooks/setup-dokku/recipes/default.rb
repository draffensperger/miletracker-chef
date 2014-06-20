# Digital Ocean doesn't provide swap, so we will set it up to allow more
swap_file '/swapfile' do
  size 1024 # MBs
  persist true
end

# Docker uses these if they aren't used by the machine (which they aren't)
docker_gateway = '172.17.42.1'
docker_subnet = '172.17.0.0/16'

# Prevent Docker from modifying firewall rules
file '/etc/default/docker' do
  content 'DOCKER_OPTS="--iptables=false"'
end

# Allow connections for http and https
firewall_rule 'http' do
  port 80
  protocol :tcp
  action :allow
end
firewall_rule 'https' do
  port 443
  protocol :tcp
  action :allow
end

# Install Dokku
# From: https://github.com/rlister/chef-dokku-simple/blob/master/recipes/default.rb
tag  = node['dokku']['tag']
root = '/home/dokku'
version = File.join(root, 'VERSION')
package 'wget'
bash 'dokku-bootstrap' do
  code "wget -qO- https://raw.github.com/progrium/dokku/#{tag}/bootstrap.sh | sudo DOKKU_TAG=#{tag} DOKKU_ROOT=#{root} bash"
  not_if { File.exists?(version) and (File.open(version).read.chomp == tag) }
end

# Include rules for docker containers to connect to external network
template '/etc/ufw/before.rules' do
  source 'before.rules'
  user 'root'
  group 'root'
  mode '0640'
  variables docker_subnet: docker_subnet
  notifies :run, 'execute[ufw-reload]', :immediately
end
execute 'ufw-reload' do
  command 'ufw reload'
  action :nothing
end

# Setup domain, you need this unless host can resolve dig +short $(hostname -f}"
vhost = node['dokku']['vhost']
if vhost
  file File.join(root, 'VHOST') do
    owner 'dokku'
    content vhost
    action :create
  end
end

# Get app info
app_config = node['dokku']['apps']
apps = node['dokku']['apps'].keys

# Create app directries
apps.each do |app|
  directory File.join(root, app) do
    owner  'dokku'
    group  'dokku'
  end
end

# Load app environment variables
app_env = {}
apps.each do |app|
  app_env[app] = EncryptedDataBagItem.load('app-env', app).to_hash
  app_env[app].delete 'id'
end

# Install database packages
pg_version = '9.3'
apt_package "postgresql-#{pg_version}"
apt_package "postgresql-contrib-#{pg_version}"
apt_package 'redis-server'

# Set up postgres to allow connections from docker containers
template "/etc/postgresql/#{pg_version}/main/postgresql.conf" do
  source 'postgresql.conf'
  owner  'postgres'
  group  'postgres'
  mode '0640'
  variables listen_addresses: "localhost, #{docker_gateway}"
  notifies :run, 'execute[restart-postgres]', :immediately
end
template "/etc/postgresql/#{pg_version}/main/pg_hba.conf" do
  source 'pg_hba.conf'
  user 'postgres'
  group 'postgres'
  mode '0640'
  variables docker_subnet: docker_subnet
  notifies :run, 'execute[restart-postgres]', :immediately
end

execute 'restart-postgres' do
  command 'service postgresql restart'
  action :nothing
end

# Expose postgres and redis ports to the docker containers
firewall_rule 'postgres-from-dokku-containers' do
  port 5432
  source docker_subnet
  destination docker_gateway
  protocol :tcp
  action :allow
end
firewall_rule 'redis-from-dokku-containers' do
  port 6379
  source docker_subnet
  destination docker_gateway
  protocol :tcp
  action :allow
end

# Get current app configurations
cur_app_conf = {}
apps.each do |app|
  cur_app_conf[app] = ''
  # Dokku may not be installed yet so check for it using which first
  if `which dokku` != ''
    cur_app_conf[app] = `dokku config #{app}`
  end
end

# Configure the postgres connections for the applications
pg_passwords = {}
apps.each do |app|
  redis = app_config[app]['redis']
  if redis
    app_env[app]['REDIS_PROVIDER'] = "redis://#{docker_gateway}:6379/#{redis}"
  end
  pg = app_config[app]['postgres']
  if pg
    pg_passwords[pg] ||= `cat /dev/urandom | head -c 30 | base64`.gsub('/','_').gsub('+','_').gsub("\n",'')
    pw = pg_passwords[pg]
    execute "Create postgres user #{pg}" do
      user 'postgres'
      command "psql -c \"CREATE USER #{pg} WITH PASSWORD '#{pw}';\""
      not_if "sudo -u postgres psql -c \"select * from pg_user where usename='#{pg}'\" | grep -c #{pg}"
    end
    execute "Create postgres database #{pg}" do
      user 'postgres'
      command "psql -c \"CREATE DATABASE #{pg} OWNER #{pg};\""
      not_if "sudo -u postgres psql -c \"select * from pg_database where datname='#{pg}'\" | grep -c #{pg}"
    end
    # Only set the DATABASE_URL if it hasn't been set before (when the database was created)
    unless cur_app_conf[app] =~ /DATABASE_URL:/
      app_env[app]['DATABASE_URL'] = "postgres://#{pg}:#{pw}@#{docker_gateway}/#{pg}"
    end
  end
end

# Apply app environment variables
apps.each do |app|
  env_set_list = ''
  app_env[app].each do |k,v|
    env_set_list += " #{k}=\"#{v}\"" unless cur_app_conf[app] =~ /#{k}:\s+\"#{v}\"/
  end

  if env_set_list != ''
    execute "Set #{app} ENVs #{env_set_list}" do
      command "dokku config:set #{app} '#{env_set_list}'"
      returns [0,1]
    end
  end
end

# Setup Dokku deployment keys
keys = EncryptedDataBagItem.load('dokku-keys', vhost).to_hash
keys.delete 'id'
keys.each do |name,key|
  bash 'sshcommand-acl-add' do
    code "echo '#{key}' | sshcommand acl-add dokku #{name}"
    not_if "cat /home/dokku/.ssh/authorized_keys | grep '#{key}'"
  end
end

# Setup TLS certificates
apps.each do |app|
  if app_config[app]['tls'] == 'true'
    tls = EncryptedDataBagItem.load('tls', "#{app}.#{vhost}").to_hash
    directory "/home/dokku/#{app}/tls" do
      user 'root'
      group 'root'
      mode '0755'
    end
    file "/home/dokku/#{app}/tls/server.crt" do
      user 'root'
      group 'root'
      mode '0400'
      content tls['crt']
    end
    file "/home/dokku/#{app}/tls/server.key" do
      user 'root'
      group 'root'
      mode '0400'
      content tls['key']
    end
  end
end

# Make it so that unmapped subdomains redirect to the vhost domain
template '/etc/nginx/sites-available/default' do
  source 'sites-available_default'
  user 'root'
  group 'root'
  mode '0644'
  variables default_redirect: "http://#{vhost}"
  notifies :run, 'execute[restart-nginx]'
end
execute 'restart-nginx' do
  command 'service nginx restart'
  action :nothing
end