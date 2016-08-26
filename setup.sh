#!/bin/bash

echo "Adding cloudant repo ..."
cat <<'EOF' > /etc/yum.repos.d/cloudant.repo
[cloudant]
name=Cloudant Repo
baseurl=http://packages.cloudant.com/rpm/$releasever/$basearch
enabled=1
gpgcheck=0
EOF


echo -e "Creating user and group for bigcouch ..."
groupadd bigcouch
useradd --home-dir /opt/bigcouch --shell /bin/bash --comment 'bigcouch user' -g bigcouch --create-home bigcouch


echo "Installing Bigcouch ..."
yum -y update
yum -y install bigcouch


mkdir -p /var/lib/bigcouch /var/log/bigcouch /tmp/bigcouch


echo "Setting Ownership & Permissions ..."
chown -R bigcouch:bigcouch /opt/bigcouch /var/lib/bigcouch /var/log/bigcouch
chmod -R 0775 /opt/bigcouch

find /opt/bigcouch/etc -type f -exec chmod 0755 {} \;
find /opt/bigcouch/etc -type d -exec chmod 0644 {} \;

chmod -R 0755 /var/lib/bigcouch
chmod -R 0777 /var/log/bigcouch


echo "Cleaning up ..."
yum clean all
rm -r /tmp/setup.sh
