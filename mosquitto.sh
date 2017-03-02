#!/bin/bash
# I am used for mosquitto installation and log reading using Travis services
# You can call me with the following parameters: install, log
# It is supposed that TRAVIS_OS_NAME is set to osx or linux.
# According to the TRAVIS_OS_NAME and the first parameter I call functions:
#  installlinux, installosx
#  loglinux, logosx

set -e # stop immediatelly on any error

LINUX_MOSQUITTO_CONF_D="/etc/mosquitto/conf.d"
LINUX_PHARO_CONF="${LINUX_MOSQUITTO_CONF_D}/pharo.conf"
LINUX_MOSQUITTO_LOG="/var/log/mosquitto/mosquitto.log"

OSX_MOSQUITTO_CONF="/usr/local/etc/mosquitto/mosquitto.conf"
OSX_MOSQUITTO_LOG="/usr/local/var/log/mosquitto.log"

function installlinux {
    echo "Installing mosquitto"
    sudo rm -f ${LINUX_MOSQUITTO_LOG}
    sudo mkdir -p "${LINUX_MOSQUITTO_CONF_D}"
    cat <<EOF | sudo tee "${LINUX_PHARO_CONF}"
log_type all
connection_messages true
log_timestamp true
EOF
    sudo apt-add-repository -y ppa:mosquitto-dev/mosquitto-ppa
    sudo apt-get update
    sudo apt-get install -y mosquitto mosquitto-clients
    echo "Testing mosquitto"
    mosquitto_pub -h localhost -p 1883 -t abc -m 'checking mosquitto connection'
    echo "Mosquitto is ready"
}

function installosx {
    echo "Installing mosquitto"
    sudo rm -f "${OSX_MOSQUITTO_LOG}"
    brew update
    brew install mosquitto
    cat <<EOF | sudo tee -a "${OSX_MOSQUITTO_CONF}"
log_dest file ${OSX_MOSQUITTO_LOG}
log_type all
connection_messages true
log_timestamp true
EOF
    brew services start mosquitto
    echo "Testing mosquitto"
    mosquitto_pub -h localhost -p 1883 -t abc -m 'checking mosquitto connection'
    echo "Mosquitto is ready"
}

function loglinux {
    sudo killall mosquitto # flush log
    echo "=== MOSQUITTO LOG (START) ==="
    cat "$LINUX_MOSQUITTO_LOG"
    echo "=== MOSQUITTO LOG (END) ==="
}

function logosx {
    brew services stop mosquitto
    echo "=== MOSQUITTO LOG (START) ==="
    cat "${OSX_MOSQUITTO_LOG}"
    echo "=== MOSQUITTO LOG (END) ==="
}

echo "Executed with parameter '$1' on '$TRAVIS_OS_NAME' -> calling function '$1$TRAVIS_OS_NAME'."
"$1$TRAVIS_OS_NAME"
