#!/usr/bin/env sh

set -e

SERVERDIR=/var/lib/devpi
MIRROR_URL=https://mirror.sjtu.edu.cn/pypi/web/simple

if [ ! -f "${SERVERDIR}/.nodeinfo" ]; then
    echo "start initialization"
    devpi-init --serverdir "${SERVERDIR}"

    (
        echo "waiting for devpi-server start"
        sleep 5
        devpi use "http://0.0.0.0:7104"
        devpi login root --password=""

        echo "set mirror for root/pypi"
        devpi index root/pypi mirror_url="${MIRROR_URL}" mirror_web_url_fmt="${MIRROR_URL}/{name}/"

        devpi logout
    ) &

else
    echo "skip initialization"
fi

exec devpi-server --serverdir "${SERVERDIR}" --host=0.0.0.0 --port=7104 "$@"