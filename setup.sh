#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "Adding repositories ..."

echo "deb http://packages.cloudant.com/debian squeeze main" > /etc/apt/sources.list.d/cloudant.list
echo "deb http://httpredir.debian.org/debian squeeze-lts main" > /etc/apt/sources.list.d/squeeze.list
echo "deb http://httpredir.debian.org/debian wheezy-backports main contrib non-free" > /etc/apt/sources.list.d/wheezy-backports.list


echo "Adding gpg key ..."
apt-key adv --keyserver keyserver.ubuntu.com --recv-key 59E01FBD15BE8E26

apt-get update -y
apt-get install -y adduser


echo -e "Creating user and group for bigcouch ..."
groupadd bigcouch
useradd --home-dir /opt/bigcouch --shell /bin/bash --comment 'bigcouch user' -g bigcouch --create-home bigcouch

usermod -G bigcouch bigcouch
usermod -G bigcouch root


echo "Installing Bigcouch ..."
apt-get install -y bigcouch

usermod -g daemon bigcouch
chown -R bigcouch:daemon /opt/bigcouch


echo "Writing Hostname override fix ..."
tee /opt/bigcouch/bin/hostname-fix <<'EOF'
#!/bin/bash

fqdn() {
    local IP=$(/bin/hostname -i | sed 's/\./-/g')
    local DOMAIN='default.pod.cluster.local'
    echo "${IP}.${DOMAIN}"
}

short() {
    local IP=$(/bin/hostname -i | sed 's/\./-/g')
    echo $IP
}

ip() {
    /bin/hostname -i
}

if [[ "$1" == "-f" ]]; then
    fqdn
elif [[ "$1" == "-s" ]]; then
    short
elif [[ "$1" == "-i" ]]; then
    ip
else
    short
fi
EOF
chmod +x /opt/bigcouch/bin/hostname-fix

echo "Writing .bashrc ..."
tee ~/.bashrc <<'EOF'
#!/bin/bash

if [ "$BIGCOUCH_USE_LONGNAME" == true ]; then
    export HOSTNAME=$(hostname -f)
else
    export HOSTNAME=$(hostname)
fi
EOF
chown bigcouch:bigcouch ~/.bashrc


mkdir -p /var/lib/bigcouch /var/log/bigcouch

echo "Setting Ownership & Permissions ..."
chown -R bigcouch:bigcouch /opt/bigcouch /var/lib/bigcouch /var/log/bigcouch
chmod -R 0775 /opt/bigcouch

find /opt/bigcouch/etc -type f -exec chmod 0755 {} \;
find /opt/bigcouch/etc -type d -exec chmod 0644 {} \;

chmod -R 0755 /var/lib/bigcouch
chmod -R 0777 /var/log/bigcouch


echo "Cleaning up ..."
apt-get clean all
rm -r /tmp/setup.sh
