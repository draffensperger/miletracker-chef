
firewall_rule "http" do
  port 80
  protocol :tcp
  action :allow
end

firewall_rule "https" do
  port 80
  protocol :tcp
  action :allow
end