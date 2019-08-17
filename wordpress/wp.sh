#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
touch "$DIR/visited.txt"

import_file()
{
        cp -f "$1" "$DIR/sites.txt"
        cat "$DIR/sites.txt" | grep "^http*"  | awk -F'/' '{ print $1"//"$3  }' | sort -u > "$DIR/sites.txt.tmp" && mv "$DIR/sites.txt.tmp" "$DIR/sites.txt"
}

is_wp()
{
        #Check the Site's Source Code
        FILE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
        wget --quiet --tries=5 --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -T 10 "$1" -O "$DIR/wp_$FILE"
        if [[ -s "$DIR/wp_$FILE" ]]
        then
                code=$(cat "$DIR/wp_$FILE" | grep -i "wp\-includes\|wp\-content" | wc -l)
                if [[ $code -gt 0 ]]
                then
                        echo "$1" >> "$DIR/wordpress.txt"
                        printf -- "\033[32m YYY_WP -> $1 \033[0m\n"
                else
                        printf -- "\033[31m NNN_WP -> $1 \033[0m\n"
                fi
        fi
        rm -f "$DIR/wp_$FILE"

        #Visit the License.txt File
        #curl -I "$1"/license.txt | grep '200 OK'

        #Visit default URLs
        #curl -I "$1"/wp-admin | grep "301 Moved Permanently"
        #curl -I "$1"/wp-login | grep "200 OK"
        #curl -I "$1"/feed/ | grep "200 OK"

        return 1
}

import_file "$1"

while [ -s "$DIR/sites.txt" ]
do
        site=$(head -1 "$DIR/sites.txt" | sed 's/&/\%26/')
        tail -n +2 "$DIR/sites.txt" > "$DIR/sites.txt.tmp" && mv "$DIR/sites.txt.tmp" "$DIR/sites.txt"
        is_visited=$(grep -w "^$site$" "$DIR/visited.txt" | wc -l)

        if [[ $is_visited -eq 0 ]]
        then
                echo "$site" >> "$DIR/visited.txt"
                echo "DOING -> $site"
                is_wp "$site" &
        fi
done
rm -f sites.txt
echo "END"
