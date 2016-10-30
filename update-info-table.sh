#!/bin/sh

if [ $# -ne 1 ]; then
echo "Please give teh parameters as # $0 <table>"
exit 1
fi

if [ ! -r titles.info -a ! -w titles.info ]; then
echo Cannot access the title file
fi

table="$1"

cp -i titles.info titles.info.backup

# set -x

cat "$table" | while read line
do
    lhs=$(echo "$line" | awk -F: '{print $1}')
    rhs=$(echo "$line" | awk -F: '{print $2}')
    
    sed -i -r -e "s@(.*)$lhs(.*)@\\1$rhs\\2@" titles.info
done
