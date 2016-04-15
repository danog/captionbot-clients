#!/bin/bash
conversationId=$(curl https://www.captionbot.ai/api/init)

if [ "$2" = "url" ]; then url="\"$1\""; else url=$(curl https://www.captionbot.ai/api/upload -F "image1=@$1");fi

curl https://www.captionbot.ai/api/message -H "Content-Type: application/json; charset=utf-8" -X POST -d '{"userMessage":'$url', "conversationId":'$conversationId'}'
