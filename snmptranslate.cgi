#!/bin/zsh
echo Content-type: text/html
echo

OID=`echo $QUERY_STRING | sed 's/[^0-9a-zA-Z.:-]//g'`
snmptranslate -mall -Td $OID 2> /dev/null | read -d '' RESP
echo $RESP | sed -n 1p | read XOID
echo $RESP | grep '  -- FROM' | head -1 | sed 's/  -- FROM[ \t]*//' | sed 's/"/\\\\"/g' | read MIB
echo $RESP | grep '  -- TEXTUAL CONVENTION' | head -1 | sed -E 's/  -- TEXTUAL CONVENTION[\t ]*//' | sed 's/"/\\\\"/g' | read TXT
echo $RESP | grep '  SYNTAX' | head -1 | sed -E 's/  SYNTAX[\t ]*//' | sed 's/"/\\\\"/g' | read SYNTAX
echo $RESP | grep '  DISPLAY-HINT' | head -1 | sed -E 's/  DISPLAY-HINT[\t ]*//' | sed 's/"/\\\\"/g' | read HINT
echo $RESP | grep '  MAX-ACCESS' | head -1 | sed -E 's/  MAX-ACCESS[\t ]*//' | sed 's/"/\\\\"/g' | read ACCESS
echo $RESP | grep '  STATUS' | head -1 | sed -E 's/  STATUS[\t ]*//' | sed 's/"/\\\\"/g' | read STATUS
echo $RESP | grep '::= ' | head -1 | sed -E 's/::= //' | sed 's/"/\\\\"/g' | read LINE
echo `echo $RESP | sed '0,/DESCRIPTION/ { /DESCRIPTION/!d }' | egrep -v '^::= '` | sed 's/^DESCRIPTION *//' | sed 's/^"//' | sed 's/"$//' | sed 's/"/\\\\"/g' | read DESCRIPTION

echo "{ \"oid\": \"$XOID\", \"mib\": \"$MIB\", \"conv\": \"$TXT\", \"syntax\": \"$SYNTAX\", \"hint\": \"$HINT\", \"access\": \"$ACCESS\", \"status\": \"$STATUS\", \"line\": \"$LINE\", \"description\": \"$DESCRIPTION\" }"

exit 0
