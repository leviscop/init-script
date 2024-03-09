if [[ -f /etc/os-release ]]; then
     # On Linux systems
     source /etc/os-release
     OS=$ID
 else
     # On systems other than Linux (e.g. Mac or FreeBSD)
     OS=$(uname)
fi
case $OS in
"alpine"|"ubuntu"|"debian" )
    echo "OS supported!";;
* )
    echo "OS unsupported! Exiting..";
    exit 0;;
esac
read -p "Generate a new machine id? " yn
case $yn in
    [Yy]* ) rm /etc/machine-id;
    systemd-machine-id-setup;;
    [Nn]* ) ;;
    * ) ;;
esac
read -p "Do you want to change the root password? " yn
case $yn in
    [Yy]* ) passwd;;
    [Nn]* ) ;;
    * ) ;;
esac
read -p "Do you want to change the ssh port? (Default: 22) " yn
case $yn in
    [Yy]* ) read -p "Enter the new ssh port: " sshport;
    sed -i "s/\(#\|\)Port .*/Port $sshport/" /etc/ssh/sshd_config;;
    [Nn]* ) ;;
    * ) ;;
esac
echo "Enabling root login via ssh.."
sed -i "/\"/! s/\(#\|\)PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config;
case $OS in
    "alpine")
        echo "Updating system..";
        sed -i "s|#\(.*v$VER.*community\)|\1|" /etc/apk/repositories;
        sed -i "s|#\(.*v$VER_SHORT.*community\)|\1|" /etc/apk/repositories;
        apk update &>/dev/null && apk add --upgrade apk-tools &>/dev/null && apk upgrade --available &>/dev/null;
        echo "Installing basic packages..";
        apk add ca-certificates curl bind-tools figlet &>/dev/null;;
    "ubuntu"|"debian")
        echo "Updating system..";
        apt-get -qq update &>/dev/null && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade &>/dev/null;
        echo "Installing basic packages..";
        DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install apt-transport-https ca-certificates curl gnupg lsb-release bind9-dnsutils figlet landscape-common &>/dev/null;;
    * ) ;;
esac
echo "Hostname is $(hostname -f)"
read -p "Do you want to change the hostname? " yn
case $yn in
    [Yy]* ) read -p "Enter a hostname: " hostname;
    echo "Setting hostname..";
    echo "$hostname" > /etc/hostname;
    hostname -F /etc/hostname;
    echo "New hostname is $(hostname -f)";;
    [Nn]* ) ;;
    * ) ;;
esac
case $OS in
    "alpine" )
        echo "Welcome to $OS!" > /etc/motd
        hostname -s | figlet | cat >> /etc/motd
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/motd-alpine >> /etc/motd;
        echo "Installing docker..";
        apk add docker &>/dev/null;
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/daemon.json -o /etc/docker/daemon.json &>/dev/null;
        rc-update add docker &>/dev/null;
        service docker restart &>/dev/null;
        echo "Installing docker-compose..";
        apk add docker-compose &>/dev/null;;
    "ubuntu" )
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/05-welcome -o /etc/update-motd.d/05-welcome; chmod +x /etc/update-motd.d/05-welcome;
        echo "Installing docker..";
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &>/dev/null;
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list &>/dev/null;
        apt-get -qq update &>/dev/null && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce docker-ce-cli containerd.io &>/dev/null;
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/daemon.json -o /etc/docker/daemon.json &>/dev/null;
        systemctl restart docker &>/dev/null;
        echo "Installing docker-compose..";
        curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>/dev/null;
        chmod +x /usr/local/bin/docker-compose &>/dev/null;;
    "debian" )
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/05-welcome -o /etc/update-motd.d/05-welcome; chmod +x /etc/update-motd.d/05-welcome;
        echo "Installing docker..";
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &>/dev/null;
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list &>/dev/null;
        apt-get -qq update &>/dev/null && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce docker-ce-cli containerd.io &>/dev/null;
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/daemon.json -o /etc/docker/daemon.json &>/dev/null;
        systemctl restart docker &>/dev/null;
        echo "Installing docker-compose..";
        curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>/dev/null;
        chmod +x /usr/local/bin/docker-compose &>/dev/null;;
    * ) ;;
esac
read -p "Set custom portainer agent port? (Default: 9001) " yn
case $yn in
    [Yy]* ) read -p "Enter the custom port: " agentport;;
    [Nn]* ) agentport=9001;;
    * ) ;;
esac
echo "Running basic containers.."
docker run -d --name ipv6nat --cap-drop ALL --cap-add NET_ADMIN --cap-add NET_RAW --cap-add SYS_MODULE --network host --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock:ro -v /lib/modules:/lib/modules:ro robbertkl/ipv6nat &>/dev/null
docker run -d -p $agentport:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest &>/dev/null
read -p "Enable monitoring? " yn
case $yn in
    [Yy]* ) mkdir -p /volume/dem &>/dev/null; curl -s https://raw.githubusercontent.com/leviscop/init-script/main/dem.conf -o /volume/dem/conf.yml &>/dev/null; read -p "Discord webhook url: " webhook; sed -i "s/<hostname>/$(hostname -s)/g" /volume/dem/conf.yml; sed -i "s#<webhook>#$webhook#g" /volume/dem/conf.yml; docker run -d --name dem --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /volume/dem/conf.yml:/app/conf.yml quaide/dem:latest &>/dev/null;;
    [Nn]* ) ;;
    * ) ;;
esac
echo "Creating basic networks.."
docker network create -d bridge --ipv6 --subnet fd00:172:20::/48 --gateway fd00:172:20::1 --subnet 172.20.0.0/16 --gateway 172.20.0.1 --attachable gateway &>/dev/null
docker network create -d bridge --ipv6 --subnet fd00:172:24::/48 --gateway fd00:172:24::1 --subnet 172.24.0.0/16 --gateway 172.24.0.1 --attachable database &>/dev/null
echo "Getting traefik configuration.."
mkdir -p /volume/proxy &>/dev/null
curl -s https://raw.githubusercontent.com/leviscop/init-script/main/traefik.toml -o /volume/proxy/traefik.toml &>/dev/null
touch /volume/proxy/acme-$(hostname -s)-dns.json && chmod 600 /volume/proxy/acme-$(hostname -s)-dns.json &>/dev/null
touch /volume/proxy/acme-$(hostname -s)-tls.json && chmod 600 /volume/proxy/acme-$(hostname -s)-tls.json &>/dev/null
sysctl -w net.core.rmem_max=2500000 &>/dev/null
echo "Done!"
echo "You can add this environment to portainer with the address: $(hostname -f):$agentport"
read -p "A system restart could be required. Do you want to restart the system? " yn
case $yn in
    [Yy]* ) reboot;;
    [Nn]* ) exit 0;;
    * ) exit 0;;
esac
exit 0
