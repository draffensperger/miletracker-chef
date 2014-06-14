file '/etc/default/docker' do
  content 'DOCKER_OPTS="--iptables=false"'
end

trackmiles_env = EncryptedDataBagItem.load('app-env', 'trackmiles').to_hash
trackmiles_env.delete 'id'

node.set['dokku'] = {
    vhost: 'davidraff.com',
    tag: 'v0.2.3',
    apps: {
        trackmilesstaging: {
            env: trackmiles_env
        }
    }
}

include_recipe 'dokku-simple'

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

ssh = EncryptedDataBagItem.load('ssh-access', 'common').to_hash
ssh['deploy_authorized_keys'].each_with_index do |key, i|
  bash 'sshcommand-acl-add' do
    code "echo '#{key}' | sshcommand acl-add dokku deploy#{i}"
  end
end

include_recipe 'docker'

docker_image 'redis:latest'
docker_image 'postgres:latest'

apt_package 'postgresql-client'

docker_container 'postgres:latest' do
  detach true
  container_name 'postgres'
  not_if { File.exists? '/var/run/postgres.cid' }
end

docker_container 'redis:latest' do
  detach true
  container_name 'redis'
  not_if { File.exists? '/var/run/redis.cid' }
end

bash 'Set trackmilesstaging REDIS_PROVIDER' do
  code <<-EOH
  REDIS_IP=`docker inspect --format '{{.NetworkSettings.IPAddress }}' redis`
  dokku config:set trackmilesstaging REDIS_PROVIDER=redis://$REDIS_IP:6379/1
  EOH
  returns [0,1]
  not_if 'dokku config trackmilesstaging | grep REDIS_PROVIDER'
end

# TODO: Secure the postgres database more carefully for staging/master/non-root users

bash 'Create postgres database' do
  code <<-EOH
  POSTGRES_IP=`docker inspect --format '{{.NetworkSettings.IPAddress}}' postgres`
  createdb -U postgres -h $POSTGRES_IP trackmiles_staging
  dokku config:set trackmilesstaging DATABASE_URL=postgres://postgres@$POSTGRES_IP/trackmiles_staging
  EOH
  returns [0,1]
  not_if 'dokku config trackmilesstaging | grep DATABASE_URL'
end