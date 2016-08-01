#!/bin/bash
# Bash captionbot client
# Created by Daniil Gentili
# Licensed under GPLv3

help() {
 echo "captionbot.ai api client.
This script will try to recognize the content of any image you give him using Microsoft's captionbot.ai website api.

Usage: $0 file
or
Usage: $0 url

Add the norate parameter to avoid the rating prompt:
Usage: $0 url norate

Add the script parameter to avoid the rating prompt and delete all output apart from the image description:
Usage: $0 url script
"
 exit 1
}
[ "$*" = "" ] && help

input="$1"

[ "$2" != "script" ] && echo "Connecting to captionbot.ai..."
conversationId=$(curl -s https://www.captionbot.ai/api/init | sed 's/"//g')


if [ ! -f "$input" ]; then
 url="\"$(curl -w "%{url_effective}\n" -L -f -s -I -S "$input" -o /dev/null | sed 's/^HTTP/http/g')\"" 2>/dev/null || { [ "$2" != "script" ] && echo "$input isn't a valid url. Please try again."; exit 1; }
else
 [ "$2" != "script" ] && echo "Uploading image..."
 url=$(curl -s https://www.captionbot.ai/api/upload -F "image1=@$input")
fi

mediainfo $(echo "$url" | sed 's/^\"//g;s/\"$//g') 2>/dev/null | grep -q Image || { [ "$2" != "script" ] && echo "It looks like $url isn't an image."; exit 1; }

[ "$2" != "script" ] && echo "Analyzing image..."
curl 'https://www.captionbot.ai/api/message' -H 'Host: www.captionbot.ai' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Content-Type: application/json; charset=utf-8' -H 'X-Requested-With: XMLHttpRequest' -H 'Referer: https://www.captionbot.ai/' -d '{"userMessage":'$url', "conversationId":"'$conversationId'"}'

result=$(curl -s 'https://www.captionbot.ai/api/message?waterMark=&conversationId='$conversationId -H 'Host: www.captionbot.ai' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-Requested-With: XMLHttpRequest' -H 'Referer: https://www.captionbot.ai/' -H 'Connection: keep-alive' | sed 's/\\"/"/g;s/^"//g;s/"$//g' | ./JSON.sh)
watermark=$(echo "$result" | sed '/\["WaterMark"\]/!d;s/\["WaterMark"\]\t//g')
message=$(echo "$result" | sed '/\["BotMessages",1\]/!d;s/\["BotMessages",1\]\t//g;s/^"//g;s/"$//g;s/\\n/ /g;s/\\//g')

[ "$2" = "script" ] && echo "$message" | grep -q "I really can't describe the picture" && exit 1

echo $message

[ "$2" = "script" ] && exit
echo


if [ "$2" != "norate" ];then
 until [ $s -gt 0 -a $s -le 5 ] 2>/dev/null ;do
  read -p "How did I do (rate 1 to 5)? " s
  [ $s -gt 0 -a $s -le 5 ] 2>/dev/null || echo "You didn't input a valid number. Please try again!"
 done
 result=$(curl -s 'https://www.captionbot.ai/api/message' -H 'Host: www.captionbot.ai' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Content-Type: application/json; charset=utf-8' -H 'X-Requested-With: XMLHttpRequest' -H 'Referer: https://www.captionbot.ai/' -X POST -d '{"conversationId":"'$conversationId'","waterMark":'$watermark', "userMessage":"'$s'"}')

 [ "$message" = "" ] && echo "Thanks for leaving your feedback!" || echo "$message"
fi
echo "Thanks for having used captionbot.ai! Do check out my other projects @ daniil.it and my boosted version of telegram's Bot API: pwrtelegram.xyz!"

exit 0
