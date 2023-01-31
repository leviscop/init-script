if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    OS=Debian
    VER=$(cat /etc/debian_version)
else
    OS=$(uname -s)
    VER=$(uname -r)
fi
VER_SHORT="${VER%.*}"
case $OS in
"Alpine Linux"|"Ubuntu"|"Debian" )
    echo "OS supported!"
    break;;
* )
    echo "OS unsupported! Exiting.."
    exit 0;;
esac
while true; do
    read -p "Do you want to change the root password? " yn
    case $yn in
        [Yy]* ) passwd; break;;
        [Nn]* ) break;;
        * ) break;;
    esac
done
case $OS in
    "Alpine Linux")
        echo "Updating system.."
        sed -i "s|#\(.*v$VER.*community\)|\1|" /etc/apk/repositories
        sed -i "s|#\(.*v$VER_SHORT.*community\)|\1|" /etc/apk/repositories
        apk update &>/dev/null && apk add --upgrade apk-tools &>/dev/null && apk upgrade --available &>/dev/null
        echo "Installing basic packages.."
        apk add ca-certificates curl bind-tools &>/dev/null
        break;;
    "Ubuntu"|"Debian")
        echo "Updating system.."
        apt-get -qq update &>/dev/null && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade &>/dev/null
        echo "Installing basic packages.."
        DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install apt-transport-https ca-certificates curl gnupg lsb-release bind9-dnsutils figlet &>/dev/null
        break;;
    * ) break;;
esac
while true; do
    echo "Hostname is $(hostname -f)"
    read -p "Do you want to change the hostname? " yn
    case $yn in
        [Yy]* ) read -e -i "$(sed 's/\.$//' <<< $(dig @1.1.1.1 -x $(wget -q -O - https://ipv4.myip.wtf/text) +short))" -p "Enter a hostname: " hostname; echo "Setting hostname.."; echo "$hostname" > /etc/hostname; hostname -F /etc/hostname; echo "New hostname is $(hostname -f)"; break;;
        [Nn]* ) break;;
        * ) break;;
    esac
done
#while true; do
#    read -p "Enable 2FA? " yn
#    case $yn in
#        [Yy]* ) google-authenticator; sed -i '/pam_google_authenticator.so/d' /etc/pam.d/common-auth; echo 'auth required pam_google_authenticator.so nullok' >> /etc/pam.d/common-auth; sed -i '/pam_google_authenticator.so/d' /etc/pam.d/sshd; echo 'auth required pam_google_authenticator.so' >> /etc/pam.d/sshd; sed -i 's/ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config; sed -i 's/KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config; sed -i '/AuthenticationMethods/d' /etc/ssh/sshd_config; echo 'AuthenticationMethods publickey,keyboard-interactive' >> /etc/ssh/sshd_config; systemctl restart sshd.service; break;;
#        [Nn]* ) break;;
#        * ) break;;
#    esac
#done
case $OS in
    "Alpine Linux" )
        echo "Installing docker.."
        apk add docker
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/daemon.json -o /etc/docker/daemon.json &>/dev/null
        rc-update add docker
        service docker restart
        echo "Installing docker-compose.."
        apk add docker-compose
        break;;
    "Ubuntu"|"Debian" )
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/05-welcome -o /etc/update-motd.d/05-welcome; chmod +x /etc/update-motd.d/05-welcome
        echo "Installing docker.."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &>/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list &>/dev/null
        apt-get -qq update &>/dev/null && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce docker-ce-cli containerd.io &>/dev/null
        curl -s https://raw.githubusercontent.com/leviscop/init-script/main/daemon.json -o /etc/docker/daemon.json &>/dev/null
        systemctl restart docker &>/dev/null
        echo "Installing docker-compose.."
        curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>/dev/null
        chmod +x /usr/local/bin/docker-compose &>/dev/null
        break;;
    * ) break;;
esac
echo "Running basic containers.."
docker run -d --name ipv6nat --cap-drop ALL --cap-add NET_ADMIN --cap-add NET_RAW --cap-add SYS_MODULE --network host --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock:ro -v /lib/modules:/lib/modules:ro robbertkl/ipv6nat &>/dev/null
docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest &>/dev/null
while true; do
    read -p "Enable monitoring? " yn
    case $yn in
        [Yy]* ) mkdir -p /volume/dem &>/dev/null; curl -s https://raw.githubusercontent.com/leviscop/init-script/main/dem.conf -o /volume/dem/conf.yml &>/dev/null; read -p "Discord webhook url: " webhook; sed -i "s/<hostname>/$(hostname -s)/g" /volume/dem/conf.yml; sed -i "s#<webhook>#$webhook#g" /volume/dem/conf.yml; docker run -d --name dem --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /volume/dem/conf.yml:/app/conf.yml quaide/dem:latest &>/dev/null; break;;
        [Nn]* ) break;;
        * ) break;;
    esac
done
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
