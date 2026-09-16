#!/usr/bin/env sh

set -e

: "${DEVPISERVER_HOST:=0.0.0.0}"
: "${DEVPISERVER_PORT:=7104}"
: "${DEVPISERVER_ROOT_PASSWORD:=password}"
: "${DEVPISERVER_USER:=devpi}"
: "${DEVPISERVER_PASSWORD:=password}"
: "${DEVPISERVER_MIRROR_INDEX:=pypi}"
: "${DEVPISERVER_LIB_INDEX:=devpi}"
: "${SOURCE_MIRROR_URL:=https://mirror.sjtu.edu.cn/pypi/web/simple}"

if [ ! -f "${DEVPISERVER_SERVERDIR}/.nodeinfo" ]; then
    echo "start initialization"
    devpi-init

    (
        echo "waiting for devpi-server start"
        sleep 5
        devpi use "http://${DEVPISERVER_HOST}:${DEVPISERVER_PORT}"
        devpi login root --password=""

        echo "setup password for root"
        devpi user -m root password="${DEVPISERVER_ROOT_PASSWORD}"

        echo "create user ${DEVPISERVER_USER}"
        devpi user -c "${DEVPISERVER_USER}" password="${DEVPISERVER_PASSWORD}"
        devpi logout  # logout from root
        devpi login "${DEVPISERVER_USER}" --password="${DEVPISERVER_PASSWORD}"

        echo "create index ${DEVPISERVER_USER}/${DEVPISERVER_MIRROR_INDEX}"
        devpi index -c "${DEVPISERVER_MIRROR_INDEX}" type=mirror mirror_url="${SOURCE_MIRROR_URL}" mirror_web_url_fmt="${SOURCE_MIRROR_URL}/{name}/"
        devpi index -c "${DEVPISERVER_LIB_INDEX}" bases="${DEVPISERVER_USER}/${DEVPISERVER_MIRROR_INDEX}" volatile=False acl_upload="${DEVPISERVER_USER}"

        devpi logout
    ) &

else
    echo "skip initialization"
fi

exec devpi-server --host="${DEVPISERVER_HOST}" --port="${DEVPISERVER_PORT}" --theme /usr/local/lib/python3.9/site-packages/devpi_semantic_ui "$@"