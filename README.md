Options for dokku-simple
Create a data bag on the fly
Fork the project
Be OK with an unencrypted public deploy key


This Project gives information on how to deploy a server to run the TrackMiles website.
This is useful for an actual deployment or for setting up a local staging or test environment.

## Setup Instructions

In this document, I'll be using the example of deploying to `localhost` on port 38214 (which could
be forwarded to a virtual machine), but to deploy to a Droplet you would just change the port and machine.

### Provision Virtual Machine, e.g. set up Ubuntu 14.04 VirtualBox or Digital Ocean Droplet, etc.
Change root password if needed (Useful for Digital Ocean boxes)

        ssh -t root@localhost 'passwd'

### Set up basic secure access via public key if not already setup

        cat ~/.ssh/id_rsa.pub | ssh root@localhost 'mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys'

### Set up Chef Locally
Install Chef

        curl -L "https://www.getchef.com/chef/install.sh" | sudo bash

Install necessary gems

        bundle install  --binstubs

Also install berkshelf locally so that Chef solo knows to install Berks files

        gem install berkshelf

Install the Berkshelf cookbooks locally

        bin/berks install

### Edit encrypted data bags

If you adapt these cookbooks for your own project, you will need to modify the
encrypted data bags, e.g.:

        EDITOR=leafpad bin/knife solo data bag edit ssh-access common

### Setup Chef on the remote machine

Note that we now use the new port number for added security.

        bin/knife solo prepare deploy@localhost nodes/trackmiles.json

        bin/knife solo prepare root@162.243.69.172

### Execute the Chef cookbook to setup the machine

If you change the Chef cookbooks, then this will need to be updated.

        ssh root@162.243.69.172
        bin/knife solo prepare root@162.243.69.172
        bin/knife solo bootstrap root@162.243.69.172 nodes/trackmiles.json -V -l debug
        bin/knife solo cook deploy@162.243.69.172 nodes/trackmiles.json -V -l debug
        bin/knife solo cook deploy@162.243.69.172 nodes/dev.json -V -l debug

This does it all at once:

        bin/knife solo cook deploy@testvm nodes/trackmiles.json -V -l debug

Try it on a DigitalOcean node.

To push code to dokku:

        git remote add test dokku@testvm:trackmiles
        git push test master

============

Add the key to Dokku by first SSH'ing into the host:

        cat ~/.ssh/id_rsa.pub | ssh -p 2222 root@localhost "sudo sshcommand acl-add dokku trackmiles"
        git remote add staging dokku@localhost:trackmiles2
        git push staging master

Need to install a dokku plugin:

        https://github.com/musicglue/dokku-user-env-compile

        ssh deploy@localhost

        ssh -p 2222 dokku@localhost

        sudo chsh -s /bin/bash dokku

Then transfer the authorized key to dokku

        cat ~/.ssh/authorized_keys | sudo sshcommand acl-add dokku trackmiles
        sudo restart ssh

Get the trackmiles code, cd to the directory then run:

### My next steps with Chef

        dokku
        https://github.com/fgrehm/chef-dokku

        need to configure dokku plugins too, e.g. for postgres and rails

        some day maybe set up PHP, etc.

        new relic
        http://community.opscode.com/cookbooks/newrelic


### Push the TrackMiles code with to the machine

Add remote
Push master to the server

### Test the deployment

Visit http://localhost (assuming forwarded ports 80 and 443).

        EDITOR=leafpad knife solo data bag create aws-access trackmiles
        EDITOR=leafpad knife solo data bag edit ssh-access common
        EDITOR=leafpad knife solo data bag edit app-env trackmiles

        nascar18

### General Plan

1. dokku-simple but with creating the buildstack separately
2. test it thoroughly on DigitalOcean. update firewall rules for 10.0.0.0/24 to SSH.
3. test it on VirtualBox