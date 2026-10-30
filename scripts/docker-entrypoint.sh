#!/bin/bash
set -e

echo "Starting docker-entrypoint.sh with parameters: $@"

[[ "$1" == "couchbase-server" ]] && {

    if [ $(whoami) = "couchbase" ]; then
        # Ensure that /opt/couchbase/var is owned by user 'couchbase' and
        # is writable
        if [ ! -w /opt/couchbase/var -o \
            $(find /opt/couchbase/var -maxdepth 0 -printf '%u') != "couchbase" ]; then
            echo "/opt/couchbase/var is not owned and writable by UID 1000"
            echo "Aborting as Couchbase Server will likely not run"
            exit 1
        fi
    fi

    if [ "$(ls -A /docker-entrypoint-initdb.d)" ]; then
        echo "Starting Couchbase Server in seed mode -- "
        exec /usr/sbin/runsvdir-start &
        sleep 15
        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sh)
                    # shellcheck disable=SC1090
                    source "$f"
                    ;;
                *)
                    ;;
            esac
            echo
        done
    else
        echo "Starting Couchbase Server in regular mode -- "
        echo "Web UI available at http://<ip>:8091"
        echo "and logs available in /opt/couchbase/var/lib/couchbase/logs"
        exec /usr/sbin/runsvdir-start
    fi
}

# if seed only do not start process
if [ ! -z "$SEED_ONLY" ]; then
	echo "Couchbase seed process done."
else
	exec "$@"
fi
