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


# computers are retarted
ln -s /dev/null /etc/inittab

echo "Installing bigcouch ..."
apt-get -t squeeze -y --force-yes install bigcouch=$apt_bigcouch_version

# ^^
rm -f /etc/inittab


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


# this script handles annoying post-init tasks automatically,
tee ~/init-node.sh <<'EOF'
#!/bin/bash

: ${BIGCOUCH_ADMIN_USER:=admin}
: ${BIGCOUCH_ADMIN_PASS:=secret}

this="$0"
host=http://localhost:5984

function finish
{
    shred -u $this > /dev/null 2>&1
}

function host_up
{
    local host="$1"
    curl -sS $host --connect-timeout 2 --head --fail > /dev/null 2>&1
}

function create_admin
{
    local host="$1"
    curl -sS -X PUT -d "\"$BIGCOUCH_ADMIN_PASS\"" $host/_config/admins/${BIGCOUCH_ADMIN_USER} > /dev/null 2>&1
}

until host_up $host
do
    sleep 1
done

create_admin $host

rm -f ~/.init-node > /dev/null 2>&1
trap finish EXIT
sleep 1
EOF
chmod +x $_
touch ~/.init-node


echo "Creating directories for $app ..."
mkdir -p /var/lib/$app /volumes/$app /data/$app


echo "Setting Ownership & Permissions ..."
chown -R $user:$user ~ /var/lib/$app /volumes/$app /data/$app


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
