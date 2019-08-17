#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
touch "$DIR/visited.txt"

clean_links_file()
{
        echo "Inizio ciclo"
        while IFS= read -r line
        do
                url=$line
                log "Analizzo $url" $DIR/log

                #Delete file:// links
                if [[ $url == file* ]]
                then
                        log "$url start with file://" $DIR/log
                        break
                fi

                #Delete Javascript:
                if [[ $url == Javascript* ]]
                then
                        log "$url start with Javascript:" $DIR/log
                        break
                fi
                if [[ $url == javascript* ]]
                then
                        log "$url start with Javascript:" $DIR/log
                        break
                fi

                #Delete tel:
                if [[ $url == tel* ]]
                then
                        log "$url start with tel:" $DIR/log
                        break
                fi

                #Delete social: flickr, twitter, youtube, facebook, google, mozilla, microsoft  and other unwanted string
                if [[ $url == *google*  ]] || [[ $url == *flickr*  ]] || [[ $url == *twitter*  ]] || [[ $url == *facebook*  ]] || [[ $url == *mozilla*  ]] || [[ $url == *microsoft*  ]] || [[ $url == *jigsaws*  ]] || [[ $url == *trenitalia*  ]] || [[ $url == *treccani*  ]] || [[ $url == *iubenda*  ]]
                then
                        log "$url contains social string" $DIR/log
                        break
                fi

                #Delete mailto:
                if [[ $url == mailto* ]]
                then
                        log "$url start with mailto:" $DIR/log
                        break
                fi
                echo "$url" | sed 's/\\//g' |  sed 's/"//g'  >> $DIR/links.txt
        done < "$1"
        time awk '!a[$0]++' "$DIR/links.txt" > $DIR/links.txt.tmp && mv $DIR/links.txt.tmp $DIR/links.txt
        echo "Fine ciclo"
        printf "\n\r"
        printf "\n\r"
        printf "\n\r"
}

log()
{
        #echo "$1"
        echo "$1" >> "$2"
}

get_links()
{
        while IFS= read -r line
        do
                #Already visited
                if grep "^$line$" "$DIR/visited.txt" #2>/dev/null
                then
                        log "$line already visited" "$DIR/log"
                        cat "$DIR/links.txt" | grep -v "^$line$" > "$DIR/links.txt.tmp" && mv "$DIR/links.txt.tmp" "$DIR/links.txt"
                        break
                fi

                FILE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

                log "--- Visito $line ---" $DIR/log
                wget --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -T 10 --quiet "$line" -O $DIR/$FILE.html
                echo $line >> "$DIR/visited.txt"

                log "Dimensione file html: $(wc -l $DIR/$FILE.html)" $DIR/log
                lynx -listonly -nonumbers -hiddenlinks=merge -dump "$DIR/$FILE.html" > "$DIR/links_$FILE.txt"
                log "Dimensione file links: $(wc -l $DIR/links_$FILE.txt)" $DIR/log
                cat "$DIR/links_$FILE.txt"
                clean_links_file "$DIR/links_$FILE.txt"

                rm -f $DIR/$FILE.html
                rm -f $DIR/links_$FILE.txt
        done < "$1"
}

echo "$1" >> "$DIR/links.txt"

while :
do
        get_links "$DIR/links.txt"
done
