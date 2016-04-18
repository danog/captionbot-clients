#!/bin/bash
# Bash captionbot client
# Created by Daniil Gentili
# Licensed under GPLv3


echo "Send me the image (or the image url) you want me to recognize."
read input
input=$(echo "$input" | sed 's/\s*//g')

echo "Connecting to captionbot.ai..."
conversationId=$(curl -s https://www.captionbot.ai/api/init)

url="\"$(curl -w "%{url_effective}\n" -L -f -s -I -S "$input" -o /dev/null)\"" || { echo "$input isn't a valid url. Please try again."; exit 1; }


echo "Analyzing image..."
result=$(curl -s https://www.captionbot.ai/api/message -H "Content-Type: application/json; charset=utf-8" -X POST -d '{"userMessage":'$url', "conversationId":'$conversationId'}' | sed 's/\\"/"/g;s/^"//g;s/"$//g'  | ./JSON.sh -s)

watermark=$(echo "$result" | sed '/\["WaterMark"\]/!d;s/\["WaterMark"\]\t//g')
message=$(echo "$result" | sed '/\[".*Message"\]/!d;s/\[".*Message"\]\t//g;s/^"//g;s/"$//g;s/\\n/ /g')

echo $message
echo
until [ $s -gt 0 -a $s -le 5 ] 2>/dev/null ;do
  echo 'How did I do? mykeyboardstartshere "1 star" "2 stars" "3 stars" "4 stars" "5 stars"'
  read s
  s=$(echo ${s//[^0-9]/})
  [ $s -gt 0 -a $s -le 5 ] 2>/dev/null || echo "You didn't input a valid number. Please try again!"
done

result=$(curl -s https://www.captionbot.ai/api/message -H "Content-Type: application/json; charset=utf-8" -X POST -d '{"userMessage":"'$s'", "conversationId":'$conversationId', waterMark:'$watermark'}' | sed 's/\\"/"/g;s/^"//g;s/"$//g'  | ./JSON.sh -s)
message=$(echo "$result" | sed '/\[".*Message"\]/!d;s/\[".*Message"\]\t//g;s/^"//g;s/"$//g')
[ "$message" = "$s" ] && echo "Thanks for leaving your feedback!" || echo "$message"


echo "Thanks for having used captionbot.ai! Do check out my other projects @ daniil.it and my live wallpaper creator bot, @mklwp_bot!"
echo "Type /start to restart the process or send me another image."

exit 0
