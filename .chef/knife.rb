knife[:solo] = true
current_dir = File.dirname(__FILE__)
log_level                :debug
log_location             STDOUT
knife[:secret_file] = ".chef/encrypted_data_bag_secret"
encrypted_data_bag_secret ".chef/encrypted_data_bag_secret"
cookbook_path    ["cookbooks", "site-cookbooks"]

# Allows multiple chef runs simultaneously
if defined? chef_zero
  chef_zero[:port] = rand(8889 .. 28889)
end

#7103
#node_path        "nodes"
#role_path        "roles"
#environment_path "environments"
#data_bag_path    "data_bags"