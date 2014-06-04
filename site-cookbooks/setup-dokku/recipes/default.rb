node.set['dokku'] = {
    tag: 'HEAD',
    vhost: 'test',
    ssh_users: 'deploy',
    apps: {
      trackmiles: {
          env: {
            TEST: 'VALUE'
          }
      }
    }
}

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