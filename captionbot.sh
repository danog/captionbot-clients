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
"
 exit 1
}
[ $* = "" ] && help

echo "Connecting to captionbot.ai..."
conversationId=$(curl -s https://www.captionbot.ai/api/init)

if [ ! -f "$1" ]; then url="\"$1\""; else echo "Uploading image..."; url=$(curl -s https://www.captionbot.ai/api/upload -F "image1=@$1");fi

echo "Analyzing image..."
result=$(curl -s https://www.captionbot.ai/api/message -H "Content-Type: application/json; charset=utf-8" -X POST -d '{"userMessage":'$url', "conversationId":'$conversationId'}' | sed 's/\\"/"/g;s/^"//g;s/"$//g'  | ./JSON.sh -s)

watermark=$(echo "$result" | sed '/\["WaterMark"\]/!d;s/\["WaterMark"\]\t//g')
message=$(echo "$result" | sed '/\[".*Message"\]/!d;s/\[".*Message"\]\t//g;s/^"//g;s/"$//g')

echo $message
echo
until [ $s -gt 0 -a $s -le 5 ] 2>/dev/null ;do
 read -p "How did I do (rate 1 to 5)? " s
 [ $s -gt 0 -a $s -le 5 ] 2>/dev/null || echo "You didn't input a valid number. PLease try again!"
done

result=$(curl -s https://www.captionbot.ai/api/message -H "Content-Type: application/json; charset=utf-8" -X POST -d '{"userMessage":"'$s'", "conversationId":'$conversationId', "waterMark":'$watermark'}' | sed 's/\\"/"/g;s/^"//g;s/"$//g'  | ./JSON.sh -s)
message=$(echo "$result" | sed '/\[".*Message"\]/!d;s/\[".*Message"\]\t//g;s/^"//g;s/"$//g')

echo $message

echo "Thanks for having used captionbot.ai!"
