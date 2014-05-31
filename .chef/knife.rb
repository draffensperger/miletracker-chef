knife[:solo] = true
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT

cookbook_path    ["cookbooks", "site-cookbooks"]
node_path        "nodes"
role_path        "roles"
environment_path "environments"
data_bag_path    "data_bags"

knife[:secret_file] = ".chef/encrypted_data_bag_secret"
encrypted_data_bag_secret ".chef/encrypted_data_bag_secret"