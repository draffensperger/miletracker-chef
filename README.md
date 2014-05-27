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

        bundle install

### Setup Chef on the remote machine
Note that we now use the new port number for added security.

        bundle exec knife solo prepare -p 38214 deploy@localhost nodes/trackmiles.json

### Execute the Chef cookbook to setup the machine

If you change the Chef cookbooks, then this will need to be updated.

        bundle exec knife solo cook -p 38214 deploy@localhost nodes/trackmiles.json

### Push the TrackMiles code with to the machine

### Test the deployment

Visit http://localhost (assuming forwarded ports 80 and 443).

## License

The MIT License (MIT)

Copyright (c) 2014 David Raffensperger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.