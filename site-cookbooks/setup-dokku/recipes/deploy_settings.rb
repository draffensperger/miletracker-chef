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
  password Opscode::OpenSSL::Password::secure_password
  action :unlock
end