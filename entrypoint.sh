#!/usr/bin/env sh

set -e

SERVERDIR=/var/lib/devpi
MIRROR_URL="${MIRROR_URL:-https://mirror.sjtu.edu.cn/pypi/web/simple}"
REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-30}"

if [ ! -f "${SERVERDIR}/.nodeinfo" ]; then
    echo "start initialization"
    devpi-init --serverdir "${SERVERDIR}"
fi

(
    echo "waiting for devpi-server start"
    until devpi use "http://0.0.0.0:7104"; do sleep 1; done
    devpi login root --password=""

    echo "set mirror for root/pypi"
    devpi index root/pypi mirror_url="${MIRROR_URL}" \
        mirror_no_project_list=True \
        mirror_web_url_fmt="${MIRROR_URL}/{name}/"

    devpi logout
) &

exec devpi-server --serverdir "${SERVERDIR}" --host=0.0.0.0 --port=7104 \
    --request-timeout "${REQUEST_TIMEOUT}" "$@"
