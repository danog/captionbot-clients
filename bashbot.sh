#!/bin/bash
# bashbot, the Telegram bot written in bash.
# Written by @topkecleon, Juan Potato (@awkward_potato), Lorenzo Santina (BigNerd95) and Daniil Gentili (@danog)
# https://github.com/topkecleon/telegram-bot-bash

# Depends on ./JSON.sh (http://github.com/dominictarr/./JSON.sh),
# which is MIT/Apache-licensed
# And on tmux (https://github.com/tmux/tmux),
# which is BSD-licensed


# This file is public domain in the USA and all free countries.
# If you're in Europe, and public domain does not exist, then haha.

TOKEN='206520417:AAEdzbpAWtd8sAxgoq04u42lhH0bYxf4Lzo'
URL='https://api.telegram.org/bot'$TOKEN

FORWARD_URL=$URL'/forwardMessage'

MSG_URL=$URL'/sendMessage'
PHO_URL=$URL'/sendPhoto'
AUDIO_URL=$URL'/sendAudio'
DOCUMENT_URL=$URL'/sendDocument'
STICKER_URL=$URL'/sendSticker'
VIDEO_URL=$URL'/sendVideo'
VOICE_URL=$URL'/sendVoice'
LOCATION_URL=$URL'/sendLocation'
ACTION_URL=$URL'/sendChatAction'
FORWARD_URL=$URL'/forwardMessage'

FILE_URL='https://api.telegram.org/file/bot'$TOKEN'/'
UPD_URL=$URL'/getUpdates?offset='
GET_URL=$URL'/getFile'
OFFSET=0
declare -A USER MESSAGE URLS CONTACT LOCATION

send_message() {
	local chat="$1"
	local text="$(echo "$2" | sed 's/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g;s/ mylongstartshere.*//g')"
	[ "$3" != "text" ] && {
		local keyboard="$(echo "$2" | sed '/mykeyboardstartshere /!d;s/.*mykeyboardstartshere //g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g;s/ mylongstartshere.*//g')"

		local file="$(echo "$2" | sed '/myfilelocationstartshere /!d;s/.*myfilelocationstartshere //g;s/ mykeyboardstartshere.*//g;s/ mylatstartshere.*//g;s/ mylongstartshere.*//g')"

		local lat="$(echo "$2" | sed '/mylatstartshere /!d;s/.*mylatstartshere //g;s/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylongstartshere.*//g')"

		local long="$(echo "$2" | sed '/mylongstartshere /!d;s/.*mylongstartshere //g;s/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g')"
	}
	if [ "$keyboard" != "" ]; then
		send_keyboard "$chat" "$text" "$keyboard"
		local sent=y
	fi
	if [ "$file" != "" ]; then
		send_file "$chat" "$file" "$text"
		local sent=y
	fi
	if [ "$lat" != "" -a "$long" != "" ]; then
		send_location "$chat" "$lat" "$long"
		local sent=y
	fi

	if [ "$sent" != "y" ];then
		res=$(curl -s "$MSG_URL" -F "chat_id=$chat" -F "text=$text")
	fi

}

send_markdown_message() {
	res=$(curl -s "$MSG_URL" -F "chat_id=$1" -F "text=$2" -F "parse_mode=markdown")
}

send_keyboard() {
	local chat="$1"
	local text="$2"
	shift 2
	local keyboard=init
	OLDIFS=$IFS
	IFS=$(echo -en "\"")
	for f in $*;do [ "$f" != " " ] && local keyboard="$keyboard, [\"$f\"]";done
	IFS=$OLDIFS
	local keyboard=${keyboard/init, /}
	res=$(curl -s "$MSG_URL" --header "content-type: multipart/form-data" -F "chat_id=$chat" -F "text=$text" -F "reply_markup={\"keyboard\": [$keyboard],\"one_time_keyboard\": true}")
}

get_file() {
	[ "$1" != "" ] && echo $FILE_URL$(curl -s "$GET_URL" -F "file_id=$1" | ./JSON.sh -s | egrep '\["result","file_path"\]' | cut -f 2 | cut -d '"' -f 2)

}

send_file() {
	[ "$2" = "" ] && return
	local chat_id=$1
	local file=$2
	echo "$file" | grep -qE '/home/allowed/.*' || return
	local ext="${file##*.}"
	case $ext in 
        	"mp3")
			CUR_URL=$AUDIO_URL
			WHAT=audio
			STATUS=upload_audio
			;;
		png|jpg|jpeg|gif)
			CUR_URL=$PHO_URL
			WHAT=photo
			STATUS=upload_photo
			;;
		webp)
			CUR_URL=$STICKER_URL
			WHAT=sticker
			STATUS=
			;;
		mp4)
			CUR_URL=$VIDEO_URL
			WHAT=video
			STATUS=upload_video
			;;

		ogg)
			CUR_URL=$VOICE_URL
			WHAT=voice
			STATUS=
			;;
		*)
			CUR_URL=$DOCUMENT_URL
			WHAT=document
			STATUS=upload_document
			;;
	esac
	send_action $chat_id $STATUS
	res=$(curl -s "$CUR_URL" -F "chat_id=$chat_id" -F "$WHAT=@$file" -F "caption=$3")
}

# typing for text messages, upload_photo for photos, record_video or upload_video for videos, record_audio or upload_audio for audio files, upload_document for general files, find_location for location

send_action() {
	[ "$2" = "" ] && return 
	res=$(curl -s "$ACTION_URL" -F "chat_id=$1" -F "action=$2")
}

send_location() {
	[ "$3" = "" ] && return
	res=$(curl -s "$LOCATION_URL" -F "chat_id=$1" -F "latitude=$2" -F "longitude=$3")
}

forward() {
	[ "$3" = "" ] && return
	res=$(curl -s "$FORWARD_URL" -F "chat_id=$1" -F "from_chat_id=$2" -F "message_id=$3")	
}

startproc() {
	rm -r $copname
	mkfifo $copname
	tmux kill-session -t $copname
	TMUX= tmux new-session -d -s $copname "./captionbot.sh bashbotmode &>$copname"
	while tmux ls | grep -q $copname;do
		read -t 10 line
		[ "$line" != "" ] && send_message "${USER[ID]}" "$line"
		line=
	done <$copname
	rm -r $copname
}

inproc() {
	tmux send-keys -t $copname "$MESSAGE ${URLS[*]}
"
}

process_client() {
	# User
	USER[FIRST_NAME]=$(echo "$res" | egrep '\["result",0,"message","chat","first_name"\]' | cut -f 2 | cut -d '"' -f 2)
	USER[LAST_NAME]=$(echo "$res" | egrep '\["result",0,"message","chat","last_name"\]' | cut -f 2 | cut -d '"' -f 2)
	USER[USERNAME]=$(echo "$res" | sed 's/^.*\(username.*\)/\1/g' | cut -d '"' -f3)

	# Audio
	URLS[AUDIO]=$(get_file $(echo "$res" | egrep '\["result",0,"message","audio","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	# Document
	URLS[DOCUMENT]=$(get_file $(echo "$res" | egrep '\["result",0,"message","document","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	# Photo
	URLS[PHOTO]=$(get_file $(echo "$res" | egrep '\["result",0,"message","photo",.*,"file_id"\]' | cut -f 2 | cut -d '"' -f 2 | sed -n '$p'))
	# Sticker
	URLS[STICKER]=$(get_file $(echo "$res" | egrep '\["result",0,"message","sticker","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	# Video
	URLS[VIDEO]=$(get_file $(echo "$res" | egrep '\["result",0,"message","video","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	# Voice
	URLS[VOICE]=$(get_file $(echo "$res" | egrep '\["result",0,"message","voice","file_id"\]' | cut -f 2 | cut -d '"' -f 2))

	# Contact
	CONTACT[NUMBER]=$(echo "$res" | egrep '\["result",0,"message","contact","phone_number"\]' | cut -f 2 | cut -d '"' -f 2)
	CONTACT[FIRST_NAME]=$(echo "$res" | egrep '\["result",0,"message","contact","first_name"\]' | cut -f 2 | cut -d '"' -f 2)
	CONTACT[LAST_NAME]=$(echo "$res" | egrep '\["result",0,"message","contact","last_name"\]' | cut -f 2 | cut -d '"' -f 2)
	CONTACT[USER_ID]=$(echo "$res" | egrep '\["result",0,"message","contact","user_id"\]' | cut -f 2 | cut -d '"' -f 2)

	# Caption
	CAPTION=$(echo "$res" | egrep '\["result",0,"message","caption"\]' | cut -f 2 | cut -d '"' -f 2)

	# Location
	LOCATION[LONGITUDE]=$(echo "$res" | egrep '\["result",0,"message","location","longitude"\]' | cut -f 2 | cut -d '"' -f 2)
	LOCATION[LATITUDE]=$(echo "$res" | egrep '\["result",0,"message","location","latitude"\]' | cut -f 2 | cut -d '"' -f 2)
	NAME="$(basename ${URLS[*]} &>/dev/null)"

	# Tmux 
	copname="CO${USER[ID]}"

	if ! tmux ls | grep -q $copname; then
		[ ! -z ${LOCATION[*]} ] && send_location "${USER[ID]}" "${LOCATION[LATITUDE]}" "${LOCATION[LONGITUDE]}"
		case $MESSAGE in
			'/info')
				send_message "${USER[ID]}" "This bot will try to recognize the content of any image you give him using Microsoft's captionbot.ai website api. Client (https://github.com/danog/captionbot-clients) created by @danogentili."
				;;
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
"
				tmux kill-session -t $copname
				rm -r $copname

				startproc&
				;;
			'')
				;;
			*)
				send_message "${USER[ID]}" "$MESSAGE" "text"
		esac
	else
		case $MESSAGE in
			'/cancel')
				tmux kill-session -t $copname
				rm -r $copname
				send_message "${USER[ID]}" "Command canceled."
				;;
			*) inproc;;
		esac
	fi
}

# source the script with source as param to use functions in other scripts
while [ "$1" != "source" ]; do {

	res=$(curl -s $UPD_URL$OFFSET | ./JSON.sh -s)

	# Target
	USER[ID]=$(echo "$res" | egrep '\["result",0,"message","chat","id"\]' | cut -f 2)
	# Offset
	OFFSET=$(echo "$res" | egrep '\["result",0,"update_id"\]' | cut -f 2)
	# Message
	MESSAGE=$(echo "$res" | egrep '\["result",0,"message","text"\]' | cut -f 2 | cut -d '"' -f 2)
	
	OFFSET=$((OFFSET+1))

	if [ $OFFSET != 1 ]; then
		process_client&

	fi

}; done
