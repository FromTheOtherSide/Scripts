#!/bin/bash

start=$(date +%s)

url='http://snapcamz.cc/showthread.php?tid=1029&page=' 
outdir='/home/user/Pictures'
page=1
end=94


for ((page=1;page<="$end";page++))
do
	printf 'Preprocessing Page %d of %d\n' "$page" "$end"
	curl -s "$url$page" | lynx -dump -listonly -force_html -stdin | grep -o 'https://.*\.jpg' > /tmp/links
	
	while read -r link
	do
		curl -s "$link" | grep -o 'https://img.*\.jpg' | sort -u > /tmp/lsmile

		curl -s --output-dir '/home/user/Pictures' -O "$(cat /tmp/lsmile)"

	done < /tmp/links
done
	#	curl --output-dir /home/user/Pictures -O < <(curl -s "$url2" | tidy -q | grep -o 'https://img.*\.jpg' |  )
