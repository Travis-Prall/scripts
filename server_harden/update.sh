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
reboot_time=6:00
UPDATE=false
FULL_UPDATE=false
DRIVERS=true
CLEAN=false
FULL_CLEAN=false
REBOOT=false
DOCKER=false
PIHOLE=false
RKHUNTER=false

function update() {
    echo "Updating ${server_name}..." 2>&1
    apt-get update -y >/dev/null
    apt-get upgrade -y >/dev/null
    echo "Update Commplete" 2>&1
}

function full_update() {
    echo "Fully Updating ${server_name}..." 2>&1
    apt-get update -y >/dev/null
    apt-get dist-upgrade -y >/dev/null
    if $DRIVERS; then
        update_drivers
    fi
    if $PIHOLE; then
        pihole -up >/dev/null
    fi
    if $RKHUNTER; then
        rkhunter --propupd >/dev/null
    fi
}


function update_drivers() {
    echo "Updating drivers" 2>&1
    ubuntu-drivers autoinstall >/dev/null
    echo "Drivers Updated" 2>&1
    
    }



function check_for_reboot() {
    echo "checking if reboot requirement" 2>&1
    if [ -f /var/run/reboot-required ]; then
        echo "REBOOT REQUIRED, sheduled for $reboot_time" 2>&1
        shutdown -r $reboot_time >/dev/null
    else
        echo "No reboot required" 2>&1
    fi
}

function maint_clean() {
    echo "Cleaning ${server_name}..." 2>&1
    echo "Removing Old Kernels . . ." 2>&1
    apt-get -y --purge autoremove >/dev/null
    apt-get autoclean -y >/dev/null
    apt-get -y clean >/dev/null
    echo "Cleaning Complete" 2>&1
}

function full_clean() {
    echo "Fully Cleaning ${server_name}..." 2>&1
    echo "Removing old Dynamic Kernel Module Support (DKMS) . . ." 2>&1
    rm -v /boot/*.old-dkms >/dev/null
    echo "Cleaning up the GRUB Boot Menu . . ." 2>&1
    update-grub >/dev/null
    echo "Clearing all Cache Memory . . ." 2>&1
    rm -rfv ~/.cache/*
    echo "Clearing all Logs . . ." 2>&1
    journalctl --vacuum-time=28d
    echo "Clearing Trash . . ." 2>&1
    rm -rf ~/.local/share/Trash/*
    if $DOCKER; then
        echo "Cleaning Docker" 2>&1
        docker system prune -af >/dev/null
    fi
    echo "Cleaning Complete" 2>&1
}

main() {
    echo "Starting Maintenance" 2>&1
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
    echo "Maintenance Complete" 2>&1
}

main "$@"
