#!/bin/bash
# Edit your commands in this file.

if [ "$1" = "source" ];then
	# Edit the token in here
	source token
	# Set INLINE to 1 in order to receive inline queries.
	# To enable this option in your bot, send the /setinline command to @BotFather.
	INLINE=0
	# Set to .* to allow sending files from all locations
	FILE_REGEX='/home/user/allowed/.*'
else

	ALLOW="${URLS[PHOTO]} ${URLS[STICKER]} ${URLS[DOCUMENT]}"
		[ ! -z $ALLOW ] && {
			send_action ${USER[ID]} typing
			if echo "$ALLOW" | grep -qE '.jpg$\|.png$\|.jpeg$'; then
				wut=$ALLOW
			else
				convert $ALLOW /tmp/$MESSAGE_ID.jpg
				wut=/tmp/$MESSAGE_ID.jpg
			fi
			result=$(./captionbot.sh $wut script)
			rm /tmp/$MESSAGE_ID.jpg &>/dev/null
			res=$(curl -s "$MSG_URL" -d "chat_id=${USER[ID]}" -d "text=$result" -d "reply_to_message_id=$MESSAGE_ID")
			return
		}
	case $MESSAGE in
		'/start')
			send_message "${USER[ID]}" "This is a bot client for captionbot.ai written in bash.
This bot will try to recognize the content of any image you give him using Microsoft's captionbot.ai website api. 

Available commands:
/start: Start bot and image recognition process.
/info: Get shorter info message about this bot.
/cancel: Cancel any currently running interactive chats.

Captionbot client written by Daniil Gentili @danogentili.
Contribute to the project: https://github.com/danog/captionbot-clients

Bot written by @topkecleon, Juan Potato (@awkward_potato), Lorenzo Santina (BigNerd95) and Daniil Gentili (@danogentili)
Contribute to the project: https://github.com/topkecleon/telegram-bot-bash

Do check out my other projects @ https://daniil.it and my other bots, @mklwp_bot and @video_dl_bot!

To start, send me a photo.
"
			;;
		*)
			#[ "$GROUP" = "y" ] && result=$(./captionbot.sh "$MESSAGE" script) && res=$(curl -s "$MSG_URL" -d "chat_id=${USER[ID]}" -d "text=$result" -d "reply_to_message_id=$MESSAGE_ID")
			;;
	esac
fi
