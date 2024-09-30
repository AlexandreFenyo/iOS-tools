[5.3.1]fenyo@virt:~/public_html/wifimapexplorer/api/v1> vi info.cgi

#!/bin/zsh

export LANG=C

cd /home/fenyo/public_html/wifimapexplorer/api/v1

date +%Y/%m/%d-%H:%M:%S | read DATE
echo "$DATE;$QUERY_STRING;$REMOTE_ADDR" >> /tmp/wifimapexplorer-api.log

echo Content-type: text/html
echo
date

# env
