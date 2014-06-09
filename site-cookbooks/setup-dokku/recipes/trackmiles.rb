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
end
execute "dokku config:set trackmiles DATABASE_URL=#{pg['Url']}"

redis = run_and_get_attrs 'dokku redis:info trackmiles'
if redis['Host'].nil? or redis['Host'] == ''
  redis = run_and_get_attrs 'dokku redis:create trackmiles'
end
execute "dokku config:set trackmiles REDIS_PROVIDER=redis://#{redis['Host']}:#{redis['Port']}/1"