#!/usr/bin/env bash

##################################################################################
#                              Author: Travis Prall                              #
#                     Creation Date: August 6, 2022 05:19 PM                     #
#                     Last Updated: August 27, 2022 08:30 AM                     #
#                          Source Language: shellscript                          #
#                                                                                #
#                            --- Code Description ---                            #
#                                  Maintenance                                   #
##################################################################################

server_name=$(hostname --long)
UPDATE=false
FULL_UPDATE=false
CLEAN=false
FULL_CLEAN=false
REBOOT=false
DOCKER=false
PIHOLE=false
RKHUNTER=false

function update() {
    echo "Updating ${server_name}..." 2>&1
    apt update -y > /dev/null
    apt upgrade -y > /dev/null
}

function full_update() {
    echo "Fully Updating ${server_name}..." 2>&1
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
    echo "checking if reboot requirement" 2>&1
    if [ -f /var/run/reboot-required ]; then
        echo "REBOOT REQUIRED, sheduled for 4:30" 2>&1
        shutdown -r 4:30 > /dev/null
    else
        echo "No reboot required" 2>&1
    fi
}

function maint_clean() {
    echo "Cleaning ${server_name}..." 2>&1
    echo "Removing Old Kernels . . ." 2>&1
    apt-get -y --purge autoremove > /dev/null
    apt-get autoclean -y > /dev/null
    apt-get -y clean > /dev/null
}

function full_clean() {
    echo "Fully Cleaning ${server_name}..." 2>&1
    echo "Removing old Dynamic Kernel Module Support (DKMS) . . ." 2>&1
    rm -v /boot/*.old-dkms > /dev/null
    echo "Cleaning up the GRUB Boot Menu . . ." 2>&1
    update-grub > /dev/null
    echo "Clearing all Cache Memory . . ." 2>&1
    rm -rfv ~/.cache/*
    echo "Clearing all Logs . . ." 2>&1
    journalctl --vacuum-time=28d
    echo "Clearing Trash . . ." 2>&1
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
        echo "No updates" 2>&1
    fi

    if $CLEAN; then
        maint_clean
    fi
    if $FULL_CLEAN; then
        full_clean
    fi
    if $REBOOT; then
        check_for_reboot
    fi

}

main "$@"