#!/bin/bash
#===============================================================================
#
#          FILE: bin/send_message.sh
# 
#         USAGE: send_message.sh [-h|--help] [format] "CHAT[ID]" "message ...." [debug]
# 
#   DESCRIPTION: send a message to the given user/group
# 
#       OPTIONS: format - normal, markdown, html (optional)
#                CHAT[ID] - ID number of CHAT or BOTADMIN to send to yourself
#                message - message to send in specified format
#                    if no format is givern send_message() format is used
#
#                -h - display short help
#                --help -  this help
#
#                Set BASHBOT_HOME to your installation directory
#
#	LICENSE: WTFPLv2 http://www.wtfpl.net/txt/copying/
#        AUTHOR: KayM (gnadelwartz), kay@rrr.de
#       CREATED: 16.12.2020 11:34
#
#### $$VERSION$$ v1.21-0-gc85af77
#===============================================================================

####
# parse args
SEND="send_message"
case "$1" in
	"nor*"|"tex*")
		SEND="send_normal_message"
		shift
		;;
	"mark"*)
		SEND="send_markdownv2_message"
		shift
		;;
	"html")
		SEND="send_html_message"
		shift
		;;
	'')
		printf "missing arguments\n"
		;&
	"-h"*)
		printf 'usage: send_message [-h|--help] [format] "CHAT[ID]" "message ...." [debug]\n'
		exit 1
		;;
	'--h'*)
		sed -n '3,/###/p' <"$0"
		exit 1
		;;
esac

# set bashbot environment
# shellcheck disable=SC1090
source "${0%/*}/bashbot_env.inc.sh" "$3" # $3 debug

####
# ready, do stuff here -----
if [ "$1" == "BOTADMIN" ]; then
	CHAT="${BOT_ADMIN}"
else
	CHAT="$1"
fi

# send message in selected format
"${SEND}" "${CHAT}" "$2"

# output send message result
jssh_printDB "BOTSENT" | sort -r

