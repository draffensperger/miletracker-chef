This Project gives information on how to deploy a server to run the TrackMiles website.
This is useful for an actual deployment or for setting up a local staging or test environment.

## Setup Instructions

In this document, I'll be using the example of deploying t `localhost` on port 38214 (which could
be forwarded to a virtual machine), but to deploy to a Droplet you would just change the port and machine.

### Provision Virtual Machine, e.g. set up Ubuntu 14.04 VirtualBox or Digital Ocean Droplet, etc.
Change root password if needed (Useful for Digital Ocean boxes)

        ssh -t root@localhost 'passwd'

### Create deploy user if not already there

        ./setup_deploy_user.sh root@localhost

# Set up basic secure access via public keys on a non-default SSH port

        ./setup_ssh_access.sh deploy@localhost ~/.ssh/id_rsa.pub 38214

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

### Edit Encrypted Data bags if needed

To create an encrypted data bag:

        EDITOR=leafpad bin/knife solo data bag create firewall trackmiles

For instance, to change the firewall rules:

        EDITOR=leafpad bin/knife solo data bag edit firewall trackmiles

### Setup Chef on the remote machine

Note that we now use the new port number for added security.

        bin/knife solo prepare -p 38214 deploy@localhost nodes/trackmiles.json

### Execute the Chef cookbook to setup the machine

If you change the Chef cookbooks, then this will need to be updated.

        bin/knife solo cook -p 38214 deploy@localhost nodes/trackmiles.json

### Push the TrackMiles code with to the machine

Add remote
Push master to the server

### Test the deployment

Visit http://localhost (assuming forwarded ports 80 and 443).
ssh -p 38214 deploy@localhost

## Sample Data Bag Files

### Sample Firewall Rules

For `data_bags/firewall/trackmiles.json` :

        {
          "id": "trackmiles",
            "rules": [
                {"http": {
                    "port": "80",
                "protocol":"tcp"
                }},
                {"https": {
                    "port": "443",
               "protocol":"tcp"
                }},
                {"ssh on custom port": {
                    "port": "38214",
                    "source": "127.0.0.1",
                    "protocol":"tcp"
                }}
            ]
        }
