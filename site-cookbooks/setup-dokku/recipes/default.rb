node.set['dokku'] = {
    tag: 'HEAD',
    apps: {
      trackmiles: {
        domain: 'test',
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