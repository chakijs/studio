#!/bin/bash


caddy_port="7081"
caddy_root="http://localhost:${caddy_port}"


# install additional packages
echo
echo "--> Installing additional studio packages for Sencha development..."
hab pkg binlink jarvus/sencha-cmd sencha


# welcome message and environment detection
echo
echo "--> Welcome to ChakiJS Studio! Detecting environment..."
if [ -z "${CHAKI_REPO}" ]; then
    CHAKI_REPO="$( cd "$( dirname "${BASH_SOURCE[1]}" )" && pwd)"
    CHAKI_REPO="${CHAKI_REPO:-/src}"
fi
echo "    CHAKI_REPO=${CHAKI_REPO}"
echo


# setup sencha cmd
echo
echo "--> Setting up Sencha CMD..."

echo "    * Use 'build-app AppName' to build an app for testing"
build-app() {
    app_name="$1"
    [ -z "$app_name" ] && { echo >&2 "Usage: build-app AppName"; return 1; }

    echo
    echo "--> Building ${app_name}..."

    pushd "${CHAKI_REPO}/sencha-workspace/${app_name}" > /dev/null

    echo "    Running: sencha app refresh"
    hab pkg exec jarvus/sencha-cmd sencha app refresh || return $?

    echo "    Running: sencha app build development"
    hab pkg exec jarvus/sencha-cmd sencha app build development || return $?

    popd > /dev/null

    echo "    Done: Open app at ${caddy_root}/${app_name}"
}


# setup caddy server
caddy-start() {
    caddy-stop

    echo
    echo "--> Launching the Caddy web server in the background..."

    echo "    Running: caddy -port ${caddy_port} -root ${CHAKI_REPO}/sencha-workspace browse"
    hab pkg exec core/caddy caddy -port "${caddy_port}" -agree -quiet -root "${CHAKI_REPO}/sencha-workspace" &
    CADDY_PID=$!
    echo "    * Open ${caddy_root} to browse sencha-workspace"

    if [[ "${HAB_DOCKER_OPTS}" != *":${caddy_port}"* ]]; then
        echo "      (If using Mac or Windows, ensure HAB_DOCKER_OPTS=\"-p ${caddy_port}:${caddy_port}\" was set when entering the studio to expose this port to your host system)"
    fi
}

caddy-stop() {
    [ -n "${CADDY_PID}" ] && {
        echo
        echo "--> Stopping web server..."
        echo "    Killing caddy process #${CADDY_PID}"
        kill "${CADDY_PID}"
        unset CADDY_PID
    }
}

caddy-start


## clean up on exit
_cbl_studio_cleanup() {
    caddy-stop
}

trap _cbl_studio_cleanup exit
