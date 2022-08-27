#!/bin/bash
##################################################################################
#                              Author: Travis Prall                              #
#                      Creation Date: June 9, 2022 08:46 AM                      #
#                     Last Updated: August 7, 2022 11:28 AM                      #
#                          Source Language: shellscript                          #
#                                                                                #
#                            --- Code Description ---                            #
#                          Run and report clamav scans                           #
##################################################################################

server_name=$(hostname --long)
LOG_DIR="/var/log"
CLAMAV_LOG_DIR="${LOG_DIR}/clamav"
CLAM_LOG="${CLAMAV_LOG_DIR}/clamav-$(date +'%Y-%m-%d').log"
EMAIL_FROM=$(whoami)@$(hostname --long)
EMAIL_TO=""
PUA=false

function clam_scan() {
    if dpkg -l clamav >/dev/null; then
        echo "Antivirus version installed: $(freshclam --version)" > /dev/null
        systemctl stop clamav-freshclam
        freshclam
        systemctl start clamav-freshclam
        if $PUA; then
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --detect-pua=yes --log=${CLAM_LOG}
        else
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --log=${CLAM_LOG}
        fi
        check_scan
    else
        echo "ClamAV is not installed for ${server_name}" | tee -a ${REPORT}
        apt-get install clamav clamav-daemon -y > /dev/null
        if $PUA; then
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --detect-pua=yes --log=${CLAM_LOG}
        else
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --log=${CLAM_LOG}
        fi
        check_scan
    fi
}

function check_scan() {
    #Check the last set of results. If there are any “Infected" counts send an email.
    echo "Checking ClamAV scan results" | tee -a ${REPORT}
    SUBJECT="VIRUS DETECTED ON ${server_name}!!!"

    if [ $(tail -n 12 ${CLAM_LOG} | grep Infected | grep -v 0 | wc -l) != 0 ]; then

        EMAILMESSAGE=$(mktemp /tmp/virus-alert.XXXXX)

        echo "To: ${EMAIL_TO}" >>${EMAILMESSAGE}

        echo "From: ${EMAIL_FROM}" >>${EMAILMESSAGE}

        echo "Subject: ${SUBJECT}" >>${EMAILMESSAGE}

        echo "Importance: High" >>${EMAILMESSAGE}

        echo "X-Priority: 1" >>${EMAILMESSAGE}

        echo "$(tail -n 50 ${CLAM_LOG})" >>${EMAILMESSAGE}

        sendmail -t <${EMAILMESSAGE}
    else
        echo "No viruses detected" | tee -a ${REPORT}

    fi

}

main() {
    clam_scan
    check_scan
}

main "$@"
