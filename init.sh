#!/bin/bash
while true; do
    read -p "Do you want to change the root password? " yn
    case $yn in
        [Yy]* ) passwd; break;;
        [Nn]* ) break;;
        * ) break;;
    esac
done
echo "Updating system.."
apt-get update -q && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade &>/dev/null
echo "Installing basic packages.."
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install apt-transport-https ca-certificates curl gnupg lsb-release bind9-dnsutils &>/dev/null
while true; do
    echo "Hostname is $(hostname -f)"
    read -p "Do you want to change the hostname? " yn
    case $yn in
        [Yy]* ) read -e -i "$(sed 's/\.$//' <<< $(dig @1.1.1.1 -x $(wget -q -O - https://ipv4.myip.wtf/text) +short))" -p "Enter a hostname: " hostname; echo "Setting hostname.."; hostnamectl set-hostname $hostname; echo "New hostname is $(hostname -f)"; break;;
        [Nn]* ) break;;
        * ) break;;
    esac
done
echo "Installing docker.."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &>/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list &>/dev/null
apt-get update -q && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce docker-ce-cli containerd.io &>/dev/null
curl -s https://raw.githubusercontent.com/leviscop/init-script/main/daemon.json -o /etc/docker/daemon.json &>/dev/null
systemctl restart docker &>/dev/null
echo "Installing docker-compose.."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>/dev/null
chmod +x /usr/local/bin/docker-compose &>/dev/null
echo "Running basic containers.."
docker run -d --name ipv6nat --cap-drop ALL --cap-add NET_ADMIN --cap-add NET_RAW --cap-add SYS_MODULE --network host --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock:ro -v /lib/modules:/lib/modules:ro robbertkl/ipv6nat &>/dev/null
docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest &>/dev/null
echo "Creating basic networks.."
docker network create -d bridge --ipv6 --subnet fd00:172:20::/48 --gateway fd00:172:20::1 --subnet 172.20.0.0/16 --gateway 172.20.0.1 --attachable gateway &>/dev/null
docker network create -d bridge --ipv6 --subnet fd00:172:24::/48 --gateway fd00:172:24::1 --subnet 172.24.0.0/16 --gateway 172.24.0.1 --attachable database &>/dev/null
echo "Getting traefik configuration.."
mkdir -p /volume/proxy &>/dev/null
curl -s https://raw.githubusercontent.com/leviscop/init-script/main/traefik.toml -o /volume/proxy/traefik.toml &>/dev/null
touch /volume/proxy/acme-$(hostname -s)-dns.json && chmod 600 /volume/proxy/acme-$(hostname -s)-dns.json &>/dev/null
touch /volume/proxy/acme-$(hostname -s)-tls.json && chmod 600 /volume/proxy/acme-$(hostname -s)-tls.json &>/dev/null
sysctl -w net.core.rmem_max=2500000 &>/dev/null
echo "Adding ssh-key for backup server"
echo "Enter root password:"
ssh root@storage-1.swarm.leviscop.net cat /volume/elkarbackup/sshkeys/id_rsa.pub | tee -a /root/.ssh/authorized_keys &>/dev/null
echo "Done!"
echo "You can add this environment to portainer with the address: $(hostname -f):9001"
while true; do
    read -p "A system restart could be required. Do you want to restart the system? " yn
    case $yn in
        [Yy]* ) reboot;;
        [Nn]* ) exit 0;;
        * ) exit 0;;
    esac
done
exit 0
