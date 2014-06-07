=begin
dokku_ssh_keys = {}
ssh = EncryptedDataBagItem.load('ssh-access', 'common').to_hash
ssh['deploy_authorized_keys'].each_with_index do |key, i|
  dokku_ssh_keys["deploy#{i}"] = key
end

trackmiles_env = EncryptedDataBagItem.load('app-env', 'trackmiles').to_hash
trackmiles_env.delete 'id'

node.set['dokku'] = {
  ssh_keys: dokku_ssh_keys,
  apps: {
    trackmiles: {
      env: trackmiles_env
    }
  },
  plugins: {
      pg_plugin: 'https://github.com/Kloadut/dokku-pg-plugin',
      redis_plugin: 'https://github.com/luxifer/dokku-redis-plugin'
      #user_env_compile: 'https://github.com/musicglue/dokku-user-env-compile'
      #postgresql_plugin: 'https://github.com/jeffutter/dokku-postgresql-plugin'
  }
}

include_recipe 'dokku::ssh_keys'
include_recipe 'dokku::apps'
include_recipe 'dokku::plugins'
=end

def run_and_get_attrs(cmd)
  out = `#{cmd}`
  # Looks for things like "User: 'root'" or "Host: 127.0.0.1"
  out.scan(/\s+(.*):\s+'?([^'\n]*)'?\s++/).reduce({}) do |map,kv|
    map[kv[0]] = kv[1]
    map
  end
end

bash 'echo hello' do
  code = 'echo hello'
  not_if do

  end
end

=begin
sudo dokku postgresql:list
PostgreSQL containers:
  - trackmilesdb
There are no PostgreSQL containers created.

sudo dokku postgresql:create trackmilesdb
sudo dokku postgresql:link trackmiles trackmilesdb

sudo dokku postgresql:info trackmilesdb
       Host: 172.17.42.1
       Port: 49154
       User: 'root'
       Password: 'O2gh3bjcYiwtQxh4'
       Database: 'db'

       Url: 'postgres://root:O2gh3bjcYiwtQxh4@172.17.42.1:49154/db'

sudo dokku redis:info trackmiles
Usage: docker inspect CONTAINER|IMAGE [CONTAINER|IMAGE...]
..

       Host:
       Public port:

sudo dokku redis:create trackmiles

       Host: 172.17.0.28
       Public port: 49155


/\s+(.*):\s+(.*)/.match(s).captures

s.scan(/\s+(.*):\s+(.*)/).map {|kv| {kv[0] => kv[1]}}

s.scan(/\s+(.*):\s+(.*)/).reduce({}) do |map,kv|
  map[kv[0]] = kv[1]
  map
end


=end