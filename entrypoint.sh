#!/usr/bin/env sh

set -e

SERVERDIR=/var/lib/devpi
MIRROR_URL="${MIRROR_URL:-https://pypi.tuna.tsinghua.edu.cn/simple}"
NVIDIA_MIRROR_URL="${NVIDIA_MIRROR_URL:-https://pypi.nvidia.cn}"
REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-120}"
ROOT_PASSWORD="${ROOT_PASSWORD:-}"

if [ ! -f "${SERVERDIR}/.nodeinfo" ]; then
    echo "start initialization"
    if [ -n "${ROOT_PASSWORD}" ]; then
        devpi-init --serverdir "${SERVERDIR}" --root-passwd "${ROOT_PASSWORD}"
    else
        devpi-init --serverdir "${SERVERDIR}"
    fi
fi

(
    echo "waiting for devpi-server start"
    until devpi use "http://0.0.0.0:7104"; do sleep 1; done

    if ! devpi login root --password="${ROOT_PASSWORD}"; then
        echo "error: failed to login as root" >&2
        echo "ROOT_PASSWORD only takes effect when the data volume is first initialized." >&2
        echo "For an existing volume, login with the old password and run:" >&2
        echo "    devpi user -m root password=<new-password>" >&2
        echo "skipping mirror configuration" >&2
        exit 0
    fi

    echo "set mirror for root/pypi"
    devpi index root/pypi mirror_url="${MIRROR_URL}" \
        mirror_no_project_list=False \
        mirror_web_url_fmt="${MIRROR_URL}/{name}/"

    if [ -n "${NVIDIA_MIRROR_URL}" ]; then
        if devpi index root/nvidia >/dev/null 2>&1; then
            echo "update mirror for root/nvidia"
            devpi index root/nvidia mirror_url="${NVIDIA_MIRROR_URL}" \
                mirror_web_url_fmt="${NVIDIA_MIRROR_URL}/{name}/"
        else
            echo "create mirror for root/nvidia"
            devpi index -c root/nvidia type=mirror \
                mirror_url="${NVIDIA_MIRROR_URL}" \
                mirror_web_url_fmt="${NVIDIA_MIRROR_URL}/{name}/"
        fi
    fi

    echo "prefetch root/pypi project list from upstream"
    python -c "import urllib.request; urllib.request.urlopen('http://0.0.0.0:7104/root/pypi/+simple/', timeout=300).read()" || true

    devpi logout
) &

exec devpi-server --serverdir "${SERVERDIR}" --host=0.0.0.0 --port=7104 \
    --request-timeout "${REQUEST_TIMEOUT}" "$@"
