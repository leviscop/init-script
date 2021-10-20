#!/bin/bash
apt-get update -q && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -q && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce docker-ce-cli containerd.io
curl -s https://raw.githubusercontent.com/leviscop/init-script/main/daemon.json -o /etc/docker/daemon.json
systemctl restart docker
docker run -d --name ipv6nat --cap-drop ALL --cap-add NET_ADMIN --cap-add NET_RAW --cap-add SYS_MODULE --network host --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock:ro -v /lib/modules:/lib/modules:ro robbertkl/ipv6nat
docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
docker network create -d bridge --ipv6 --subnet fd00:172:20::/48 --gateway fd00:172:20::1 --subnet 172.20.0.0/16 --gateway 172.20.0.1 --attachable gateway
docker network create -d bridge --ipv6 --subnet fd00:172:24::/48 --gateway fd00:172:24::1 --subnet 172.24.0.0/16 --gateway 172.24.0.1 --attachable database
mkdir -p /volume
chown 1000:1000 /volume
curl -s https://raw.githubusercontent.com/leviscop/init-script/main/.stignore -o /volume/.stignore
mkdir -p /volume/proxy
curl -s https://raw.githubusercontent.com/leviscop/init-script/main/traefik.toml -o /volume/proxy/traefik.toml
touch /volume/proxy/acme-$(hostname -s)-dns.json && chmod 600 /volume/proxy/acme-$(hostname -s)-dns.json
touch /volume/proxy/acme-$(hostname -s)-tls.json && chmod 600 /volume/proxy/acme-$(hostname -s)-tls.json
sysctl -w net.core.rmem_max=2500000
exit 0
