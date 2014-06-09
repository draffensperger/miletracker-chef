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