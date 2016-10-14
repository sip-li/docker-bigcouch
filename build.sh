#!/bin/bash

set -e

app=bigcouch
user=$app

export DEBIAN_FRONTEND=noninteractive


# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)


echo "Creating user and group for $user ..."
useradd --system --home-dir ~ --create-home --shell=/bin/false --user-group $user


echo "Installing squeeze repo .."
echo "deb http://archive.debian.org/debian squeeze main" > /etc/apt/sources.list.d/squeeze.list
echo 'APT::Default-Release "jessie";' > /etc/apt/apt.conf.d/99-default-release


echo "Installing cloudant repo ..."
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 59E01FBD15BE8E26
echo "deb http://packages.cloudant.com/debian wheezy main" > /etc/apt/sources.list.d/cloudant.list

apt-get update


echo "Calculating versions for $app ..."
apt_bigcouch_version=$(apt-cache show $app | grep ^Version | grep $BIGCOUCH_VERSION | sort -n | head -1 | awk '{print $2}')
echo "$app: $apt_bigcouch_version"


echo "Installing deps ..."
apt-get install -y curl


echo "Installing bigcouch ..."
apt-get -t squeeze -y --force-yes install bigcouch=$apt_bigcouch_version


echo "adding bin directory to path ..."
tee  /etc/profile.d/90-bigcouch-paths.sh <<EOF
if [[ -d \$HOME/bin ]]
then
    PATH=\$HOME/bin:\$PATH
fi
if [[ -d ~/$(ls ~ | grep erts)/bin ]]
then
    PATH=\$HOME/$(ls ~ | grep erts)/bin:\$PATH
fi

export PATH
export ERL_LIBS=\$HOME/lib:\$ERL_LIBS
EOF


echo "Creating directories for $app ..."
mkdir -p /var/lib/bigcouch /volumes/$app
    # /var/log/bigcouch \
    # /tmp/bigcouch


echo "Setting Ownership & Permissions ..."
# chown -R bigcouch:bigcouch \
#     ~ \
#     /opt/bigcouch \
#     /var/lib/bigcouch \
#     /var/log/bigcouch \
#     /tmp/bigcouch
chown -R $user:$user /var/lib/bigcouch /volumes/$app

# chmod -R 0775 /opt/bigcouch
# chmod -R 0755 /var/lib/bigcouch
# chmod -R 0777 /var/log/bigcouch

# find /opt/bigcouch/etc -type f -exec chmod 0755 {} \;
# find /opt/bigcouch/etc -type d -exec chmod 0644 {} \;

# chmod +x ~/.bashrc


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
