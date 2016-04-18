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
conversationId=$(curl -s https://www.captionbot.ai/api/init)


if [ ! -f "$input" ]; then
 url="\"$(curl -w "%{url_effective}\n" -L -f -s -I -S "$input" -o /dev/null | sed 's/^HTTP/http/g')\"" 2>/dev/null || { [ "$2" != "script" ] && echo "$input isn't a valid url. Please try again."; exit 1; }
else
 [ "$2" != "script" ] && echo "Uploading image..."
 url=$(curl -s https://www.captionbot.ai/api/upload -F "image1=@$input")
fi

mediainfo $(echo "$url" | sed 's/^\"//g;s/\"$//g') 2>/dev/null | grep -q Image || { [ "$2" != "script" ] && echo "It looks like $url isn't an image."; exit 1; }

[ "$2" != "script" ] && echo "Analyzing image..."
result=$(curl -s https://www.captionbot.ai/api/message -H "Content-Type: application/json; charset=utf-8" -X POST -d '{"userMessage":'$url', "conversationId":'$conversationId'}' | sed 's/\\"/"/g;s/^"//g;s/"$//g'  | ./JSON.sh -s)

watermark=$(echo "$result" | sed '/\["WaterMark"\]/!d;s/\["WaterMark"\]\t//g')
message=$(echo "$result" | sed '/\[".*Message"\]/!d;s/\[".*Message"\]\t//g;s/^"//g;s/"$//g;s/\\n/ /g')

echo $message

[ "$2" = "script" ] && exit
echo


if [ "$2" != "norate" ];then
 until [ $s -gt 0 -a $s -le 5 ] 2>/dev/null ;do
  read -p "How did I do (rate 1 to 5)? " s
  [ $s -gt 0 -a $s -le 5 ] 2>/dev/null || echo "You didn't input a valid number. Please try again!"
 done

 result=$(curl -s https://www.captionbot.ai/api/message -H "Content-Type: application/json; charset=utf-8" -X POST -d '{"conversationId":'$conversationId', waterMark:'$watermark', "userMessage":"'$s'"}' | sed 's/\\"/"/g;s/^"//g;s/"$//g'  | ./JSON.sh -s)
 message=$(echo "$result" | sed '/\[".*Message"\]/!d;s/\[".*Message"\]\t//g;s/^"//g;s/"$//g')

 [ "$message" = "$s" ] && echo "Thanks for leaving your feedback!" || echo "$message"
fi
echo "Thanks for having used captionbot.ai! Do check out my other projects @ daniil.it and my live wallpaper creator bot, @mklwp_bot!"

exit 0
