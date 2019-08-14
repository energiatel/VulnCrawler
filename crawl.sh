#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
touch "$DIR/visited.txt"

clean_links_file()
{	
	while IFS= read -r line
	do
		url=$line
		log "Analizzo $url" $DIR/log
		
		#Delete file:// links
		if [[ $url == file* ]]
		then
			log "$url start with file://" $DIR/log
			continue
		fi
		
		#Delete Javascript:		
		if [[ $url == Javascript* ]]
		then
			log "$url start with Javascript:" $DIR/log
			continue
		fi
		if [[ $url == javascript* ]]
		then
			log "$url start with Javascript:" $DIR/log
			continue
		fi
		
		#Delete tel:
		if [[ $url == tel* ]]
		then
			log "$url start with tel:" $DIR/log
			continue
		fi
		
		#Delete media files:
		if [[ $url == *jpg ]] || [[ $url == *png ]]
		then
			log "$url start with tel:" $DIR/log
			continue
		fi
		
		#Delete social: flickr, twitter, youtube, facebook, google, mozilla, microsoft	and other unwanted string
		if [[ $url == *google*  ]] || [[ $url == *flickr*  ]] || [[ $url == *twitter*  ]] || [[ $url == *facebook*  ]] || [[ $url == *mozilla*  ]] || [[ $url == *microsoft*  ]] || [[ $url == *jigsaws*  ]] || [[ $url == *trenitalia*  ]] || [[ $url == *treccani*  ]] || [[ $url == *iubenda*  ]] || [[ $url == *w3*  ]] || [[ $url == *amazon*  ]] || [[ $url == *linkedin*  ]] || [[ $url == *corriere*  ]] || [[ $url == *hwupgrade*  ]] || [[ $url == *wiki*  ]] || [[ $url == *clickbank*  ]] || [[ $url == *repubblica*  ]] || [[ $url == *ilsole24ore*  ]] || [[ $url == *localhost*  ]] || [[ $url == *instagram*  ]]
		then
			log "$url contains social string" $DIR/log
			continue
		fi
		
		#Delete mailto:		
		if [[ $url == mailto* ]]
		then
			log "$url start with mailto:" $DIR/log
			continue
		fi
		
		echo "$url" | sed 's/\\//g' |  sed 's/"//g'  >> "$DIR/links.txt"
	done < "$1"
	#awk '!a[$0]++' "$DIR/links.txt" > "$DIR/links.txt.tmp" && mv "$DIR/links.txt.tmp" "$DIR/links.txt"
}

log()
{
	#echo "$1"
	echo "$1" >> "$2"
}

get_links()
{	
		FILE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
		
		log "--- Visito $1 ---" "$DIR/log"
		wget --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -T 10 --quiet "$1" -O "$DIR/$FILE.html"
		lynx -listonly -nonumbers -hiddenlinks=merge -dump "$DIR/$FILE.html" > "$DIR/links_$FILE.txt"
		#cat "$DIR/$FILE.html" | grep -o -E '\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))' >> "$DIR/links_$FILE.txt"
		
		if [[ -s "$DIR/links_$FILE.txt" ]]
		then
			clean_links_file "$DIR/links_$FILE.txt"
		fi
		
		rm -f "$DIR/$FILE.html"
		rm -f "$DIR/links_$FILE.txt"
}

echo "$1" >> "$DIR/links.txt"

while [ -s "$DIR/links.txt" ]
do	
	site=$(head -1 "$DIR/links.txt" | sed 's/&/\%26/')
	tail -n +2 "$DIR/links.txt" > "$DIR/links.txt.tmp" && mv "$DIR/links.txt.tmp" "$DIR/links.txt"
	is_visited=$(grep -w "^$site$" "$DIR/visited.txt" | wc -l)
	printf "\n\r"
	echo "$site is_visited=$is_visited"
	if [[ $is_visited -gt 0 ]]
	then
		echo "DUPLICATE"
		printf "\n\r"
	else
		echo "$site" >> "$DIR/visited.txt"
		echo "DOING -> $site"
		get_links "$site" &
	fi
done
echo "FINE"
