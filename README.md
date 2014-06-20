## Trackmiles Setup Instructions

These Chef cookbooks allow configuring a Dokku light weight PaaS for my personal projects hosted
at subdomains of davidraff.com.

### Set up Chef Locally

Install Chef on your developer machine

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

        EDITOR=leafpad bin/knife solo data bag edit ssh-access core-server

### Provision Virtual Machine

I use a Digital Ocean Droplet with Ubuntu 14.04.

### Configure your SSH to reuse connections

Knife solo will run faster if it can re-use SSH connections to transfer files and execute code.
Modify your `~/.ssh/config` file by adding these lines to re-use SSH connections:

        Host *
            ControlMaster auto
            ControlPath ~/.ssh/control:%h:%p:%r

### Run Chef on the remote machine

To re-use the connections, open an SSH connectoin in one terminal tab to the host, e.g.

        ssh root@162.243.69.172

Then run knife solo to bootstrap the node:

        bin/knife solo bootstrap root@162.243.69.172 nodes/dokku-davidraff.json

If you need to re-run the cookbook, use the `deploy` user and the `cook` command:

        bin/knife solo cook deploy@162.243.69.172 nodes/dokku-davidraff.json

To run it with debug output you can add `-V -l debug` to the end of the command.

### Deploy the code with git

Fetch the code for trackmiles

        git clone https://github.com/draffensperger/miletracker.git

Then in the `miletracker` folder, add git remote repositories

        git remote add stage dokku@162.243.69.172:stagetrackmiles
        git push stage master

Then migrate the database changes

        ssh deploy@162.243.69.172 "dokku run stagetrackmiles rake db:migrate"

### Visit the site

The staging site should now be live at https://stagetrackmiles.davidraff.com

## License

Apache 2.0