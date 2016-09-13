
#!/bin/bash
#set -euo pipefail
# something something folders
mkdir -p /var/lib/nginx
mkdir -p /var/log
mkdir -p /var/log/nginx
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run

cd /opt/app

# rm -rf /var/project
if [ ! -d "/var/project" ]; then
    mkdir -p /var/project
    HOME=/var PKG_RESOURCES_CACHE_ZIP_MANIFESTS=true ./venv/bin/trac-admin /var/project initenv "My Project" "sqlite:db/trac.db"
    HOME=/var PKG_RESOURCES_CACHE_ZIP_MANIFESTS=true ./venv/bin/trac-admin /var/project deploy /var/project
    sed -i -e 's/src = .*/src =/g' /var/project/conf/trac.ini
    sed -i -e 's/log_type = .*/log_type = file/g' /var/project/conf/trac.ini
    sed -i -e 's/log_file = .*/log_file = \/var\/log\/trac.log/g' /var/project/conf/trac.ini
    sed -i -e 's/log_level = .*/log_level = INFO/g' /var/project/conf/trac.ini
    cp -Rf /opt/app/.sandstorm/plugins /var/project
fi

TRACD_PID=/var/run/tracd
# Spawn tracd
HOME=/var PKG_RESOURCES_CACHE_ZIP_MANIFESTS=true ./venv/bin/tracd -d --base-path= --pidfile=$TRACD_PID -s --port 3050 /var/project

# Wait for tracd to startup
while [ ! -e $TRACD_PID ] ; do
    echo "waiting for tracd to be available at $TRACD_PID"
    sleep .2
done

# Start nginx.
/usr/sbin/nginx -c /opt/app/.sandstorm/service-config/nginx.conf -g "daemon off;"

