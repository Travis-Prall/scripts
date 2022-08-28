#!/bin/bash
##################################################################################
#                              Author: Travis Prall                              #
#                      Creation Date: June 9, 2022 08:46 AM                      #
#                     Last Updated: August 28, 2022 11:28 AM                     #
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
REPORT=$(mktemp /tmp/virus-alert.html.XXXXX)

# Test if report file exsists
test -f "$REPORT" || touch /tmp/virus-alert.html

# A little CSS and table layout to make the report look a little nicer
echo "<HTML>
<HEAD>
<style>
.good{font-size: 1em; color: white; background:#0863CE; padding: 0.1em 0.2em;}
.great{font-size: 1em; color: white; background:green; padding: 0.1em 0.2em;}
.warning{font-size: 1em; color: white; background:yellow; padding: 0.1em 0.2em;}
.bad{font-size: 1em; color: yellow; background: red; padding: 0.1em 0.2em;}
table
{
border-collapse:collapse;
width: 100%;
}
th
{
text-align: center;
}
tr:nth-child(even) 
{
  background-color: #f2f2f2;
}
tr:hover 
{
  background-color: coral;
}

table, td, th
{
border:1px solid black;
}
</style>
<meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
<title>Virus Scan</title>
</HEAD>
<BODY>" >"$REPORT"

echo "<h1>Virus scan for $HOST</h1>
PUA: $PUA<br>" >"$REPORT"

function clam_scan() {
    if dpkg -l clamav >/dev/null; then
        echo "<h4>Antivirus version installed: $(freshclam --version)</h4>" >>"$REPORT"
        systemctl stop clamav-freshclam >/dev/null
        freshclam >/dev/null
        systemctl start clamav-freshclam >/dev/null
        if $PUA; then
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --detect-pua=yes --log="${CLAM_LOG}"
        else
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --log="${CLAM_LOG}"
        fi
        check_scan
    else
        echo "<h2>ClamAV is not installed for ${server_name}</h2>" | tee -a "${REPORT}"
        apt-get install clamav clamav-daemon -y >/dev/null
        if $PUA; then
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --detect-pua=yes --allmatch --log="${CLAM_LOG}"
        else
            clamscan -r / --exclude-dir="^/sys" --quiet --infected --log="${CLAM_LOG}"
        fi
        check_scan
    fi
}

function format_log() {
    echo "<table border='1' style='width:100%'>
      <tr><th class='bad'>Virus</th>
      </tr>" >>"$REPORT"
    while read -r line; do
        {
            echo "<tr><td align='left'>"
            echo "$line"
            echo "</td></tr>"
        } >>"$REPORT"
    done < <(${CLAM_LOG})
}

function check_scan() {
    #Check the last set of results. If there are any “Infected" counts send an email.
    echo "Checking ClamAV scan results" 2>&1

    if [ $(tail -n 12 "${CLAM_LOG}" | grep Infected | grep -v 0 | wc -l) != 0 ]; then
        format_log
        (
            echo "To: ${EMAIL_TO}"

            echo "From: ${EMAIL_FROM}"

            echo "Content-Type: text/html;"

            echo "Subject: VIRUS DETECTED ON ${server_name}!!!"

            echo "Importance: High"

            echo "X-Priority: 1"

            cat "$REPORT"
        ) | sendmail -t
    else
        (
            echo "To: ${EMAIL_TO}"

            echo "From: ${EMAIL_FROM}"

            echo "Content-Type: text/html;"

            echo "Subject: No virus on ${server_name}!!!"

            cat "$REPORT"
        ) | sendmail -t

    fi

}

main() {
    echo "Starting ClamAV check" 2>&1
    clam_scan
    echo "Finished ClamAV check" 2>&1
}

main "$@"
