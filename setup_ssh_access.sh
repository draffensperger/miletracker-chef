#!/bin/bash
# Usage ./setup_ssh_access.sh [SSH initial login] [public key] [new port]
# Example ./setup_ssh_access.sh deploy@127.0.0.1 ~/.ssh/id_rsa.pub
echo "Configuring SSH host '$1' to use public key $2 on port $3 ..."
cat $2 | ssh $1 'mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys;'
ssh -t $1 "\
sudo sed -i 's|[#]PasswordAuthentication .*|PasswordAuthentication no|g' /etc/ssh/sshd_config;\
sudo sed -i 's|UsePAM yes|UsePAM no|g' /etc/ssh/sshd_config;\
sudo sed -i 's/PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config;\
sudo restart ssh"