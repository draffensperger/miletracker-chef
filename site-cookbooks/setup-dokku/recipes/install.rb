buildstep_url = 'https://github.com/progrium/buildstep/releases/download/2014-03-08/2014-03-08_429d4a9deb.tar.gz'
buildstep_path = '/home/deploy/buildstep.tgz'

# The buildstep download in chef-dokku would timeout, so I made this separate
# I know that remote_file resource is recommended over this, but because it's
# a huge (about 350MB) file, curl seems to work better.
bash 'Download buildstep image with curl' do
  code "curl --tlsv1 -o #{buildstep_path} -L #{buildstep_url}"
  not_if do
    File.exists?(buildstep_path)
  end
end

node.set['dokku'] = {
    git_revision: 'master',
    buildstack: {
        use_prebuilt: true,
        image_name: 'progrium/buildstep',
        prebuilt_url: buildstep_path
    },
    plugins: {
        pg_plugin: 'https://github.com/Kloadut/dokku-pg-plugin',
        redis_plugin: 'https://github.com/luxifer/dokku-redis-plugin'
    }
}

include_recipe 'dokku::bootstrap'

# TODO: delete the downloaded buildstep file as it's no longer needed