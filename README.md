This Project gives information on how to deploy a server to run the TrackMiles website.
This is useful for an actual deployment or for setting up a local staging or test environment.

## Setup Instructions

In this document, I'll be using the example of deploying to `localhost` on port 38214 (which could
be forwarded to a virtual machine), but to deploy to a Droplet you would just change the port and machine.

### Provision Virtual Machine, e.g. set up Ubuntu 14.04 VirtualBox or Digital Ocean Droplet, etc.
Change root password if needed (Useful for Digital Ocean boxes)

        ssh -t root@localhost 'passwd'

### Create deploy user if not already there

        ./setup_deploy_user.sh root@localhost

### Set up basic secure access via public keys, custom SSH port

        cat ~/.ssh/id_rsa.pub | ssh -p 2222 deploy@localhost 'mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys'
        ./setup_ssh_access.sh deploy@localhost ~/.ssh/id_rsa.pub 38214

You can change the host settings in `~/.ssh/config`, to make ssh use the port automatically, e.g.

        Host example.com
            Port 1234

### Set up Chef Locally
Install Chef

        curl -L "https://www.getchef.com/chef/install.sh" | sudo bash

Install necessary gems

        bundle install  --binstubs

Also install berkshelf locally so that Chef solo knows to install Berks files

        gem install berkshelf

Install the Berkshelf cookbooks locally

        bin/berks vendor cookbooks/
        bin/berks install

### Edit encrypted data bags

If you adapt these cookbooks for your own project, you will need to modify the
encrypted data bags, like `data_bags/firewall/trackmiles.json`. To edit, run:

        EDITOR=leafpad bin/knife solo data bag edit firewall trackmiles

Here's an example file that only allows SSH access from a single IP address.

        {
          "id": "trackmiles",
            "rules": [
                {"ssh from limited hosts": {
                    "port": "22",
                    "source": "10.0.2.2",
                    "protocol": "tcp"
                }}
            ]
        }

### Setup Chef on the remote machine

Note that we now use the new port number for added security.

        bin/knife solo prepare -p 2222 deploy@localhost nodes/trackmiles.json

### Execute the Chef cookbook to setup the machine

If you change the Chef cookbooks, then this will need to be updated.

        bin/knife solo cook -p 2222 deploy@localhost nodes/trackmiles.json

Set up Dokku

        wget -qO- https://raw.github.com/progrium/dokku/master/bootstrap.sh | sudo bash

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

        EDITOR=leafpad knife solo data bag create test_encrypted test