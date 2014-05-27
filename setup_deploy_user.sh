#!/bin/bash
# Usage ./setup_deploy_user.sh [ssh login]
# Example ./setup_deploy_user.sh '-p 2222 root@localhost'
echo Setting up user deploy for $1 ...
ssh -t @$1 "\
sudo useradd -s /bin/bash deploy;\
sudo passwd deploy;\
sudo adduser deploy sudo;\
sudo mkdir /home/deploy;\
sudo chown deploy:deploy /home/deploy -R;\
"