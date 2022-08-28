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
REPORT=$(mktemp /tmp/server_report.html.XXXXX)

# Test if report file exsists
test -f "$REPORT" || touch /tmp/server_report.html

# A little CSS and table layout to make the report look a little nicer
echo "<HTML>
<HEAD>
<style>
.good{font-size: 1em; color: white; background:#0863CE; padding: 0.1em 0.2em;}
.great{font-size: 1em; color: white; background:green; padding: 0.1em 0.2em;}
.warning{font-size: 1em; color: white; background:yellow; padding: 0.1em 0.2em;}
.bad{font-size: 1em; color: yellow; background: red; padding: 0.1em 0.2em;}
.loghead{font-size: 1em; color: white; background: black; padding: 0.1em 0.2em;}
.logs{font-size: 0.75em; color: black; background: light grey; padding: 0.1em 0.2em;}
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
</HEAD>
<BODY>" >"$REPORT"

# View hostname and insert it at the top of the html body

echo "<h1>Filesystem usage for $HOST</h1>
<h4>Last updated: <strong>$(date)</strong></h4>
<h4>System uptime and Load:<strong>$(uptime)</h4>" >>"$REPORT"

function system_info() {
  echo "<table border='1' style='width:100%'>
  <tr><th class='good'>System</th>
  <th class='good'>Info</td>
  </tr>" >>"$REPORT"
  while read -r line; do
    {
      echo "<tr><td align='left'>"
      echo "$line" | awk -F: '{print $1}'
      echo "</td><td align='left'>"
      echo "$line" | awk -F: '{print $2}'
      echo "</td></tr>"
    } >>"$REPORT"
  done < <(hostnamectl)
  echo "</table><br><br>" >>"$REPORT"
}

function logged_in_users() {
  echo "<table border='1' style='width:100%'>
  <tr><th class='good'>Logged in Users</th>
  </tr>" >>"$REPORT"
  while read -r line; do
    {
      echo "<tr><td align='left'>"
      echo "$line"
      echo "</td></tr>"
    } >>"$REPORT"
  done < <(who)
  echo "</table><br><br>" >>"$REPORT"
}

function time_check() {
  local column2=""
  echo "<table border='1' style='width:100%'>
  <tr><th class='good'>Time System</th>
  <th class='good'>Info</th>
  </tr>" >>"$REPORT"
  while read -r line; do
    [ -z "$line" ] && continue
    {
      echo "<tr><td align='left'>"
      echo "$line" | awk -F: '{print $1}'
      column2=$(awk -F":" '{print $2}' <<<"$line")
      if [ "$column2" = "" ]; then
        echo "</td></tr>"
      else
        echo "</td><td align='left' >"
        echo "$column2"
        echo "</td></tr>"
      fi
    } >>"$REPORT"
  done < <(timedatectl)
  echo "</table><br><br>" >>"$REPORT"
}

function rsyslog_check() {
  local log_report=false
  echo "<table border='1' style='width:100%' >
    <tr><th class='great' colspan='4' >Rsyslog</th>
    </tr>" >>"$REPORT"
  if dpkg -l rsyslog >/dev/null; then
    while read -r line; do
      if [ "$line" == "" ]; then
        log_report=true
        echo "<tr><th class='loghead' colspan='4' >Logs</th>
    </tr>" >>"$REPORT"
      fi
      [ -z "$line" ] && continue
      if $log_report; then
        {
          echo "<tr class='logs'><td align='left'>"
          echo "$line" | awk '{print $1,$2,$3}'
          echo "</td><td align='left'>"
          echo "$line" | awk '{print $4}'
          echo "</td><td align='left'>"
          echo "$line" | awk '{print $5}'
          echo "</td><td align='left'>"
          echo "$line" | awk '{$1 = "";$2 = "";$3 = "";$4 = ""; $5 = "";print $0;}'
          echo "</td></tr>"
        } >>"$REPORT"
      else
        {
          echo "<tr><td align='left' colspan='4' >"
          echo "$line"
          echo "</td></tr>"
        } >>"$REPORT"
      fi
    done < <(service rsyslog status)
  else
    {
      echo "<tr><td align='center'>"
      echo "Rsyslog is not installed"
      echo "</td></tr>"
    } >>"$REPORT"
  fi
  echo "</table><br><br>" >>"$REPORT"
}

function fail2ban_check() {

  if dpkg -l fail2ban >/dev/null; then
    echo "<table border='1' style='width:100%'>
        <tr><th class='great'>fail2ban</th>
        </tr>" >>"$REPORT"
    while read -r line; do
      {
        echo "<tr><td align='left'>"
        echo "$line"
        echo "</td></tr>"
      } >>"$REPORT"
    done < <(systemctl status fail2ban)
    while read -r line; do
      {
        echo "<tr><td align='left'>"
        echo "$line"
        echo "</td></tr>"
      } >>"$REPORT"
    done < <(fail2ban-client status)
  else
    {
      echo "<table border='1' style='width:100%'>
        <tr><th class='bad'>fail2ban</th>
        </tr>"
      echo "<tr><td align='center'>"
      echo "Fail2ban is not installed"
      echo "</td></tr>"
    } >>"$REPORT"
  fi
  echo "</table><br><br>" >>"$REPORT"
}

function ufw_check() {
  if dpkg -l ufw >/dev/null; then
    echo "<table border='1' style='width:100%'>
      <tr><th class='great'>UFW</th>
      </tr>" >>"$REPORT"
    while read -r line; do
      {
        echo "<tr><td align='left'>"
        echo "$line"
        echo "</td></tr>"
      } >>"$REPORT"
    done < <(ufw status verbose)
  else
    {
      echo "<table border='1' style='width:100%'>
        <tr><th class='bad'>UFW</td>
        </tr>"
      echo "<tr><td align='center'>"
      echo "UFW is not installed"
      echo "</td></tr>"
    } >>"$REPORT"
  fi
  echo "</table><br><br>" >>"$REPORT"
}

function clam_check() {
  if dpkg -l clamav >/dev/null; then
    echo "<table border='1' style='width:100%'>
      <tr><th class='great'>Clamav</th>
      </tr>" >>"$REPORT"
    while read -r line; do
      {
        echo "<tr><td align='left'>"
        echo "$line"
        echo "</td></tr>"
      } >>"$REPORT"
    done < <(clamscan --version)
  else
    {
      echo "<table border='1' style='width:100%'>
        <tr><th class='bad'>Clamav</th>
        </tr>"
      echo "<tr><td align='center'>"
      echo "Clamav is not installed"
      echo "</td></tr>"
    } >>"$REPORT"
  fi
  echo "</table><br><br>" >>"$REPORT"
}

function rkhunter_check() {
  if dpkg -l rkhunter >/dev/null; then
    echo "<table border='1' style='width:100%'>
      <tr><th class='great'>Rkhunter</th>
      </tr>" >>"$REPORT"
    while read -r line; do
      [ -z "$line" ] && continue
      {
        echo "<tr><td align='left'>"
        echo "$line"
        echo "</td></tr>"
      } >>"$REPORT"
    done < <(rkhunter --version)
  else
    {
      echo "<table border='1' style='width:100%'>
        <tr><th class='bad'>RKHunter</th>
        </tr>"
      echo "<tr><td align='center'>"
      echo "Rkhunter is not installed"
      echo "</td></tr>"
    } >>"$REPORT"
  fi
  echo "</table><br><br>" >>"$REPORT"
}

function filesystem_usage() {
  echo "<table border='1' style='width:100%'>
  <tr><th class='good'>Filesystem</th>
  <th class='good'>Size</th>
  <th class='good'>Used</th>
  <th class='good'>Avail</th>
  <th class='good'>Use %</th>
  </tr>" >>"$REPORT"
  while read -r line; do
    {
      echo "<tr><td align='center'>"
      echo "$line" | awk '{print $1}'
      echo "</td><td align='center'>"
      echo "$line" | awk '{print $2}'
      echo "</td><td align='center'>"
      echo "$line" | awk '{print $3}'
      echo "</td><td align='center'>"
      echo "$line" | awk '{print $4}'
      echo "</td><td align='center'>"
      echo "$line" | awk '{print $5}'
      echo "</td></tr>"
    } >>"$REPORT"
  done < <(df -h | grep -vi filesystem)
  echo "</table><br><br>" >>"$REPORT"
}

function user_installed_packages() {
  echo "<table border='1' style='width:100%'>
      <tr><th class='great'>User Installed Packages</th>
      </tr>" >>"$REPORT"
  while read -r line; do
    {
      echo "<tr><td align='left'>"
      echo "$line"
      echo "</td></tr>"
    } >>"$REPORT"
  done < <(comm -13 <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort) <(comm -23 <(dpkg-query -W -f='${Package}\n' | sed 1d | sort) <(apt-mark showauto | sort)))
}

function report() {
  (
    echo "To: ${EMAIL_TO}"
    echo "From: ${EMAIL_FROM}"
    echo "Content-Type: text/html; "
    echo "Subject: ${EMAIL_SUBJECT}"
    cat "$REPORT"
  ) | sendmail -t
}

main() {
  echo "Starting Report" 2>&1
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
  echo "Finished Report" 2>&1
}

main "$@"
