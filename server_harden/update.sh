#!/bin/bash



server_name=$(hostname --long)
UPDATE=false
FULL_UPDATE=false
CLEAN=false
FULL_CLEAN=false
REBOOT=false
DOCKER=false
PIHOLE=false
RKHUNTER=false



# Making sure this script is run by bash to prevent mishaps
if [ "$(ps -p "$$" -o comm=)" != "bash" ]; then
    bash "$COMMAND" "$ARGS"
    exit "$?"
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "This script must be run as root / with sudo"
fi

function update() {
    echo "Updating ${server_name}..."
    apt update -y > /dev/null
    apt upgrade -y > /dev/null
}


function full_update() {
    echo "Fully Updating ${server_name}..." > /dev/null
    apt-get update -y > /dev/null
    apt-get dist-upgrade -y > /dev/null
    if $PIHOLE; then
        pihole -up > /dev/null
    fi
    if $RKHUNTER; then
        rkhunter --propupd > /dev/null
    fi
}



function check_for_reboot() {
    echo "checking for reboot requirement" > /dev/null
    if [ -f /var/run/reboot-required ]; then
        echo "REBOOT REQUIRED, sheduled for 4:30" > /dev/null
        shutdown -r 7:30 2>&1
    else
        echo "No reboot required" > /dev/null
    fi
}



function clean() {
    echo "Cleaning ${server_name}..." > /dev/null
    echo "Removing Old Kernels . . ." > /dev/null
    apt-get -y --purge autoremove > /dev/null
    apt-get autoclean -y > /dev/null
    apt-get -y clean > /dev/null
}

function full_clean() {
    echo "Fully Cleaning ${server_name}..." > /dev/null
    echo "Removing old Dynamic Kernel Module Support (DKMS) . . ." > /dev/null
    rm -v /boot/*.old-dkms > /dev/null
    echo "Cleaning up the GRUB Boot Menu . . ." > /dev/null
    update-grub > /dev/null
    echo "Clearing all Cache Memory . . ." > /dev/null
    rm -rfv ~/.cache/*
    echo "Clearing all Logs . . ." > /dev/null
    journalctl --vacuum-time=28d
    echo "Clearing Trash . . ." > /dev/null
    rm -rf ~/.local/share/Trash/*
    if $DOCKER; then
        docker system prune -af > /dev/null
    fi
}


main() {
    if $UPDATE; then
        update
    elif $FULL_UPDATE; then
        full_update
    else
        echo "No updates" >/dev/null
    fi

    if $CLEAN; then
        echo "Cleaning" >/dev/null
        clean
    fi
    if $FULL_CLEAN; then
        echo "Cleaning" >/dev/null
        full_clean
    fi
    if $REBOOT; then
        echo "Checking for Reboot" >/dev/null
        reboot
    fi

}

main "$@"