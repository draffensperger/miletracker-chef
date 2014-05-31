# From
# https://github.com/edelight/chef-solo-search/blob/14943e4f1a0b541bb7cf2187f5100df24f97dfc8/libraries/search/overrides.rb
def load_data_bag(bag_name, bag_item_id)
  if Chef::Config[:encrypted_data_bag_secret]
    begin
      bag_item = Chef::EncryptedDataBagItem.load(bag_name, bag_item_id).to_hash
    rescue Chef::EncryptedDataBagItem::DecryptionFailure,Chef::EncryptedDataBagItem::UnacceptableEncryptedDataBagItemFormat
      bag_item = nil
    rescue NoMethodError => e
      raise e unless e.message =~ /undefined method `unpack' for/
      bag_item = nil
    rescue ArgumentError => e
      raise e unless e.message =~ /data must not be empty/
      bag_item = nil
    rescue NameError => e
      raise e unless e.message =~ /`format_version' for Chef::EncryptedDataBagItem::Decryptor:Module/
      bag_item = nil
    end

  end

  bag_item ||= data_bag_item(bag_name.to_s, bag_item_id)
end

#
# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: ufw
# Recipe:: databag
#
# Copyright 2011, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#flatten the run_list to just the names of the roles and recipes in order
def run_list_names(run_list)
  names = []
  run_list.each do |entry|
    Chef::Log.debug "ufw::databag:run_list_names+name: #{entry.name}"
    if entry.name.index('::') #cookbook::recipe
      names.push(entry.name.sub('::', '__'))
    else
      names.push(entry.name)
    end
    if entry.role?
      rol = search(:role, "name:#{entry.name}")[0]
      names.concat(run_list_names(rol.run_list))
    end
  end
  Chef::Log.debug "ufw::databag:run_list_names+names: #{names}"
  return names
end

rlist = run_list_names(node.run_list)
rlist.uniq!
Chef::Log.debug "ufw::databag:rlist: #{rlist}"

fw_db = data_bag('firewall')
Chef::Log.debug "ufw::databag:firewall:#{fw_db}"

node.override['firewall']['rules'] = [] unless node['firewall']['rules'].respond_to? :concat

rlist.each do |entry|
  Chef::Log.debug "ufw::databag: \"#{entry}\""
  if fw_db.member?(entry)
    #add the list of firewall rules to the current list

    ## Changed by David Raffensperger to support encrypted data bags
    item = load_data_bag('firewall', entry)

    rules = item['rules']
    node.override['firewall']['rules'] = node['firewall']['rules'].concat(rules) unless rules.nil?
  end
end

#now go apply the rules
include_recipe "ufw::default"