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
  }
}

include_recipe 'dokku::ssh_keys'
include_recipe 'dokku::apps'
include_recipe 'dokku::plugins'

def run_and_get_attrs(cmd)
  out = `#{cmd}`
  # Looks for things like "User: 'root'" or "Host: 127.0.0.1"
  out.scan(/[ \t]*(.+):[ \t]*'?([^'\n]*)'?[ \t]*/).reduce({}) do |map,kv|
    map[kv[0]] = kv[1]
    map
  end
end

pg = run_and_get_attrs 'dokku postgresql:info trackmilesdb'
if pg['Host'].nil? or pg['Host'] == ''
  pg = run_and_get_attrs 'dokku postgresql:create trackmilesdb'
  execute 'dokku postgresql:link trackmiles trackmilesdb'
end
trackmiles_env['DATABASE_URL'] = pg['Url']

redis = run_and_get_attrs 'dokku redis:info trackmiles'
if redis['Host'].nil? or redis['Host'] == ''
  redis = run_and_get_attrs 'dokku redis:create trackmiles'
end
trackmiles_env['REDIS_PROVIDER'] = "redis://#{redis['Host']}:#{redis['Port']}/1"

# Reset app env
node.set['dokku']['trackmiles']['env'] = trackmiles_env
include_recipe 'dokku::apps'


def set_docker_env(img, tag, name, val)
  bash "Set ENV #{name}=#{val} for docker image #{img}:#{tag}"  do
    code <<-EOF
    rm /tmp/env.cid
    docker run --cidfile=/tmp/env.cid --env #{name}=#{val} #{img} true
    CID_ENV_SET=`cat /tmp/env.cid`
    docker commit $CID_ENV_SET #{img}:#{tag}
    docker rm $CID_ENV_SET
    rm /tmp/env.cid
    EOF
    not_if do
      `docker inspect --format='{{.Config.Env}}' #{img}:#{tag}` =~ /#{name}=#{val}/
    end
  end
end

# Set longer timeout for heroku-buildpack-ruby to support slower connections
# See https://github.com/heroku/heroku-buildpack-ruby/blob/master/lib/language_pack/fetcher.rb
set_docker_env 'progrium/buildstep', 'latest', 'CURL_TIMEOUT', '600'
set_docker_env 'progrium/buildstep', 'latest', 'CURL_CONNECT_TIMEOUT', '30'

# The chef-dokku recipe created the dokku user locked but it needs to be
# unlocked to do a git push to the dokku git folder
user 'dokku' do
  password ssh['deploy_sudo_password']
  action :unlock
end

def set_file_var(file, name, value)
  old_line_regex = /#{name}=.*/
  new_line = "#{name}=#{value}"
  file = Chef::Util::FileEdit.new(file)
  file.search_file_replace_line(old_line_regex, new_line)
  file.insert_line_if_no_match(old_line_regex, new_line)
  file.write_file
end

# See http://docs.docker.io/installation/ubuntulinux/#docker-and-ufw
set_file_var '/etc/default/ufw', 'DEFAULT_FORWARD_POLICY', '"ACCEPT"'
execute 'ufw reload'

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