#!/bin/bash

##################################################################################
#                              Author: Travis Prall                              #
#                     Creation Date: August 7, 2022 10:40 AM                     #
#                     Last Updated: August 27, 2022 08:34 AM                     #
#                          Source Language: shellscript                          #
#                                                                                #
#                            --- Code Description ---                            #
#                               Email Report Stats                               #
##################################################################################

# Variables
HOST=$(hostname --long)
EMAIL_FROM=$(whoami)@$(hostname --long)
EMAIL_TO=""
EMAIL_SUBJECT="Report for ${HOST}"
REPORT=/tmp/server_report.html

# Test if report file exsists
test -f "$REPORT" || touch /tmp/server_report.html

# A little CSS and table layout to make the report look a little nicer
echo "<HTML>
<HEAD>
<style>
.good{font-size: 1em; color: white; background:#0863CE; padding: 0.1em 0.2em;}
.great{font-size: 1em; color: white; background:green; padding: 0.1em 0.2em;}
.bad{font-size: 1em; color: yellow; background: red; padding: 0.1em 0.2em;}
table
{
border-collapse:collapse;
}
table, td, th
{
border:1px solid black;
}
</style>
<meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
</HEAD>
<BODY>" > $REPORT


# View hostname and insert it at the top of the html body

echo "Filesystem usage for host <strong>$HOST</strong><br>
Last updated: <strong>$(date)</strong><br>
System uptime and Load:<strong>$(uptime)<br><br>" >> $REPORT

function system_info() {
  echo "<table border='1'>
  <tr><th class='good'>System</td>
  <th class='good'>Info</td>
  </tr>" >> $REPORT
  while read line; do
  echo "<tr><td align='left'>" >> $REPORT
  echo $line | awk -F: '{print $1}'  >> $REPORT
  echo "</td><td align='left'>" >> $REPORT
  echo $line | awk -F: '{print $2}'  >> $REPORT
  echo "</td></tr>" >> $REPORT
  done < <(hostnamectl)
  echo "</table><br><br>" >> $REPORT
}

function logged_in_users() {
  echo "<table border='1'>
  <tr><th class='good'>Logged in Users</td>
  </tr>" >> $REPORT
  while read line; do
  echo "<tr><td align='left'>" >> $REPORT
  echo $line  >> $REPORT
  echo "</td></tr>" >> $REPORT
  done < <(who)
  echo "</table><br><br>" >> $REPORT
} 

function time_check() {
  echo "<table border='1'>
  <tr><th class='good'>Time System</td>
  <th class='good'>Info</td>
  </tr>" >> $REPORT
  while read line; do
  echo "<tr><td align='left'>" >> $REPORT
  echo $line | awk -F: '{print $1}'  >> $REPORT
  echo "</td><td align='left'>" >> $REPORT
  echo $line | awk -F: '{print $2}'  >> $REPORT
  echo "</td></tr>" >> $REPORT
  done < <(timedatectl)
  echo "</table><br><br>" >> $REPORT
}


function rsyslog_check() {
    echo "<table border='1'>
    <tr><th class='great'>Rsyslog</td>
    </tr>" >> $REPORT
    if dpkg -l rsyslog >/dev/null; then
      while read line; do
      echo "<tr><td align='left'>" >> $REPORT
      echo $line  >> $REPORT
      echo "</td></tr>" >> $REPORT
      done < <(service rsyslog status)   
    else
        echo "<tr><td align='center'>" >> $REPORT
        echo "Rsyslog is not installed"  >> $REPORT
        echo "</td></tr>" >> $REPORT
    fi
    echo "</table><br><br>" >> $REPORT
}


function fail2ban_check() {

    if dpkg -l fail2ban >/dev/null; then
        echo "<table border='1'>
        <tr><th class='great'>fail2ban</td>
        </tr>" >> $REPORT
        while read line; do
        echo "<tr><td align='left'>" >> $REPORT
        echo $line  >> $REPORT
        echo "</td></tr>" >> $REPORT
        done < <(systemctl status fail2ban)   
        while read line; do
        echo "<tr><td align='left'>" >> $REPORT
        echo $line  >> $REPORT
        echo "</td></tr>" >> $REPORT
        done < <(fail2ban-client status)   
    else
        echo "<table border='1'>
        <tr><th class='bad'>fail2ban</td>
        </tr>" >> $REPORT
        echo "<tr><td align='center'>" >> $REPORT
        echo "Fail2ban is not installed"  >> $REPORT
        echo "</td></tr>" >> $REPORT
    fi
    echo "</table><br><br>" >> $REPORT
}

function ufw_check() {
    if dpkg -l ufw >/dev/null; then
      echo "<table border='1'>
      <tr><th class='great'>UFW</td>
      </tr>" >> $REPORT
      while read line; do
      echo "<tr><td align='left'>" >> $REPORT
      echo $line  >> $REPORT
      echo "</td></tr>" >> $REPORT
      done < <(ufw status verbose)   
    else
        echo "<table border='1'>
        <tr><th class='bad'>UFW</td>
        </tr>" >> $REPORT
        echo "<tr><td align='center'>" >> $REPORT
        echo "UFW is not installed"  >> $REPORT
        echo "</td></tr>" >> $REPORT
    fi
    echo "</table><br><br>" >> $REPORT
}

function clam_check() {
    if dpkg -l clamav >/dev/null; then
      echo "<table border='1'>
      <tr><th class='great'>Clamav</td>
      </tr>" >> $REPORT
      while read line; do
      echo "<tr><td align='left'>" >> $REPORT
      echo $line  >> $REPORT
      echo "</td></tr>" >> $REPORT
      done < <(clamscan --version)   
    else
        echo "<table border='1'>
        <tr><th class='bad'>Clamav</td>
        </tr>" >> $REPORT
        echo "<tr><td align='center'>" >> $REPORT
        echo "Clamav is not installed"  >> $REPORT
        echo "</td></tr>" >> $REPORT
    fi
    echo "</table><br><br>" >> $REPORT
}

function rkhunter_check() {
    if dpkg -l rkhunter >/dev/null; then
      echo "<table border='1'>
      <tr><th class='great'>Rkhunter</td>
      </tr>" >> $REPORT
      while read line; do
      echo "<tr><td align='left'>" >> $REPORT
      echo $line  >> $REPORT
      echo "</td></tr>" >> $REPORT
      done < <(rkhunter --version)   
    else
        echo "<table border='1'>
        <tr><th class='bad'>RKHunter</td>
        </tr>" >> $REPORT
        echo "<tr><td align='center'>" >> $REPORT
        echo "Rkhunter is not installed"  >> $REPORT
        echo "</td></tr>" >> $REPORT
    fi
    echo "</table><br><br>" >> $REPORT
}

function filesystem_usage() {
  echo "<table border='1'>
  <tr><th class='good'>Filesystem</td>
  <th class='good'>Size</td>
  <th class='good'>Used</td>
  <th class='good'>Avail</td>
  <th class='good'>Use %</td>
  </tr>" >> $REPORT
  while read line; do
  echo "<tr><td align='center'>" >> $REPORT
  echo $line | awk '{print $1}' >> $REPORT
  echo "</td><td align='center'>" >> $REPORT
  echo $line | awk '{print $2}' >> $REPORT
  echo "</td><td align='center'>" >> $REPORT
  echo $line | awk '{print $3}' >> $REPORT
  echo "</td><td align='center'>" >> $REPORT
  echo $line | awk '{print $4}' >> $REPORT
  echo "</td><td align='center'>" >> $REPORT
  echo $line | awk '{print $5}' >> $REPORT
  echo "</td></tr>" >> $REPORT
  done < <(df -h | grep -vi filesystem)
  echo "</table><br><br>" >> $REPORT
}

function user_installed_packages() {
      echo "<table border='1'>
      <tr><th class='great'>User Installed Packages</td>
      </tr>" >> $REPORT
      while read line; do
      echo "<tr><td align='left'>" >> $REPORT
      echo $line  >> $REPORT
      echo "</td></tr>" >> $REPORT
      done < <(comm -13 <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort) <(comm -23 <(dpkg-query -W -f='${Package}\n' | sed 1d | sort) <(apt-mark showauto | sort)) )  
}

function report() {
(
  echo "To: ${EMAIL_TO}"
  echo "From: ${EMAIL_FROM}"
  echo "Content-Type: text/html; "
  echo "Subject: ${EMAIL_SUBJECT}"
  echo
  cat $REPORT
) | sendmail -t
}

main() {
    system_info
    filesystem_usage
    time_check
    logged_in_users
    rsyslog_check
    fail2ban_check
    ufw_check
    clam_check
    rkhunter_check
    report
}

main "$@"