buildstep_url = 'https://github.com/progrium/buildstep/releases/download/2014-03-08/2014-03-08_429d4a9deb.tar.gz'
buildstep_dir = '/home/deploy'
buildstep_file = 'buildstep.tgz'
buildstep_path = "#{buildstep_dir}/#{buildstep_file}"

# The buildstep download in chef-dokku would timeout, so I made this separate
# I know that remote_file resource is recommended over this, but because it's
# a huge (about 350MB) file, curl seems to work better.
bash 'Download buildstep image with curl' do
  code "curl -o #{buildstep_path} -L #{buildstep_url}"
  not_if do
    File.exists?(buildstep_path)
  end
end

node.set['dokku'] = {
    domain: 'testvm',
    git_revision: 'master',
    buildstack: {
        use_prebuilt: true,
        image_name: 'progrium/buildstep',
        prebuilt_url: buildstep_path
    }
}

include_recipe 'dokku::bootstrap'

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
