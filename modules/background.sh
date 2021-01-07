#!/bin/bash
# file: modules/background.sh
# do not edit, this file will be overwritten on update

# This file is public domain in the USA and all free countries.
# Elsewhere, consider it to be WTFPLv2. (wtfpl.net/txt/copying)
#
# shellcheck disable=SC1117,SC2059
#### $$VERSION$$ v1.21-26-g0d3a53a

# will be automatically sourced from bashbot

# source once magic, function named like file
eval "$(basename "${BASH_SOURCE[0]}")(){ :; }"

######
# interactive and background functions

# old syntax as aliases
background() {
	start_back "${CHAT[ID]}" "$1" "$2"
}
startproc() {
	start_proc "${CHAT[ID]}" "$1" "$2"
}
checkback() {
	check_back "${CHAT[ID]}" "$1"
}
checkproc() {
	check_proc "${CHAT[ID]}" "$1"
}
killback() {
	kill_back  "${CHAT[ID]}" "$1"
}
killproc() {
	kill_proc "${CHAT[ID]}" "$1"
}

# inline and background functions
# $1 chatid
# $2 program
# $3 jobname
# $4 $5 parameters
start_back() {
	local cmdfile; cmdfile="${DATADIR:-.}/$(procname "$1")$3-back.cmd"
	printf '%s\n' "$1:$3:$2" >"${cmdfile}"
	restart_back "$@"
}
restart_back() {
	local fifo; fifo="${DATADIR:-.}/$(procname "$1" "back-$3-")"
	printf "%s: Start background job CHAT=%s JOB=%s CMD=%s\n" "$(date)" "$1" "${fifo##*/}" "${2##*/} $4 $5" >>"${UPDATELOG}"
	check_back "$1" "$3" && kill_proc "$1" "back-$3-"
	nohup bash -c "{ $2 \"$4\" \"$5\" \"${fifo}\" | \"${SCRIPT}\" outproc \"$1\" \"${fifo}\"; }" &>>"${fifo}.log" &
	sleep 0.5 # give bg job some time to init
}


# $1 chatid
# $2 program
# $3 $4 parameters
start_proc() {
	[ -z "$2" ] && return
	[ -x "${2%% *}" ] || return 1
	local fifo; fifo="${DATADIR:-.}/$(procname "$1")"
	printf "%s: Start interactive script CHAT=%s JOB=%s CMD=%s\n" "$(date)" "$1" "${fifo##*/}" "$2 $3 $4" >>"${UPDATELOG}"
	check_proc "$1" && kill_proc "$1"
	mkfifo "${fifo}"
	nohup bash -c "{ $2 \"$4\" \"$5\" \"${fifo}\" | \"${SCRIPT}\" outproc \"$1\" \"${fifo}\"
		rm \"${fifo}\"; [ -s \"${fifo}.log\" ] || rm -f \"${fifo}.log\"; }" &>>"${fifo}.log" &
}


# $1 chatid
# $2 jobname
check_back() {
	check_proc "$1" "back-$2-"
}

# $1 chatid
# $2 prefix
check_proc() {
	[ -n "$(proclist "$(procname "$1" "$2")")" ]
	# shellcheck disable=SC2034
	res=$?; return $?
}

# $1 chatid
# $2 jobname
kill_back() {
	kill_proc "$1" "back-$2-"
	rm -f "${DATADIR:-.}/$(procname "$1")$2-back.cmd"
}


# $1 chatid
# $2 prefix
kill_proc() {
	local fifo prid
	fifo="$(procname "$1" "$2")"
	prid="$(proclist "${fifo}")"
	fifo="${DATADIR:-.}/${fifo}"
	printf "%s: Stop interactive / background CHAT=%s JOB=%s\n" "$(date)" "$1" "${fifo##*/}" >>"${UPDATELOG}"
	# shellcheck disable=SC2086
	[ -n "${prid}" ] && kill ${prid}
	[ -s "${fifo}.log" ] || rm -f "${fifo}.log"
	[ -p "${fifo}" ] && rm -f "${fifo}";
}

# $1 chatid
# $2 message
send_interactive() {
	local fifo; fifo="${DATADIR:-.}/$(procname "$1")"
	[ -p "${fifo}" ] && printf '%s\n' "$2" >"${fifo}" & # not blocking!
}

# old style but may not work because of local checks
inproc() {
	send_interactive "${CHAT[ID]}" "${MESSAGE[0]}"
}

# start stop all jobs
# $1 command
#	killb*
#	suspendb*
#	resumeb*
job_control() {
	local BOT ADM content proc CHAT job fifo killall=""
	BOT="$(getConfigKey "botname")"
	ADM="$(getConfigKey "botadmin")"
	debug_checks "Enter job_control" "$1"
	for FILE in "${DATADIR:-.}/"*-back.cmd; do
		[ "${FILE}" = "${DATADIR:-.}/*-back.cmd" ] && printf "${RED}No background processes.${NN}" && break
		content="$(< "${FILE}")"
		CHAT="${content%%:*}"
		job="${content#*:}"
		proc="${job#*:}"
		job="${job%:*}"
		fifo="$(procname "${CHAT}" "${job}")" 
		debug_checks "Execute job_control" "$1" "${FILE##*/}"
		case "$1" in
		"resumeb"*|"backgr"*)
			printf "Restart Job: %s %s\n" "${proc}" " ${fifo##*/}"
			restart_back "${CHAT}" "${proc}" "${job}"
			# inform botadmin about stop
			[ -n "${ADM}" ] && send_normal_message "${ADM}" "Bot ${BOT} restart background jobs ..." &
			;;
		"suspendb"*)
			printf "Suspend Job: %s %s\n" "${proc}" " ${fifo##*/}"
			kill_proc "${CHAT}" "${job}"
			# inform botadmin about stop
			[ -n "${ADM}" ] && send_normal_message "${ADM}" "Bot ${BOT} suspend background jobs ..." &
			killall="y"
			;;
		"killb"*)
			printf "Kill Job: %s %s\n" "${proc}" " ${fifo##*/}"
			kill_proc "${CHAT}" "${job}"
			rm -f "${FILE}" # remove job
			# inform botadmin about stop
			[ -n "${ADM}" ] && send_normal_message "${ADM}" "Bot ${BOT} kill  background jobs ..." &
			killall="y"
			;;
		esac
		# send message only onnfirst job
		ADM=""
	done
	debug_checks "end job_control" "$1"
	# kill all requestet. kill ALL background jobs, even not listed in data-bot-bash
	[ "${killall}" = "y" ] && killallproc "back-"
}
