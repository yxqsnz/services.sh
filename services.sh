#!/bin/bash
VERSION="0.2.0"
AUTHORS="yxqsnz"
BASE_PATH="${HOME}/.services"
UNIT_PATH="${BASE_PATH}/units"
PID_PATH="${BASE_PATH}/pids"
LOGS_PATH="${BASE_PATH}/logs"
shopt -s nullglob

file.Exists() {
	[[ -f $1 ]] || [[ -d $1 ]] || readlink "$1" >/dev/null
}

process.isAlive() {
	ps -p "$1" >/dev/null
}

process.Stat() {
	ps -O rss,%cpu,etime -p "$1" | tail -n1
}

internal.Prepare() {
	file.Exists "$UNIT_PATH" || mkdir -p "$UNIT_PATH"
	file.Exists "$PID_PATH" || mkdir -p "$PID_PATH"
	file.Exists "$LOGS_PATH" || mkdir -p "$LOGS_PATH"
}

_start() {
	internal.Prepare

	if [ "$1" = "" ]; then
		echo "Error: I need a unit."
		return 1
	fi

	if file.Exists "$UNIT_PATH/$1"; then
		source "${UNIT_PATH}/$1"
		mv -b "$LOGS_PATH/$NAME.log" "$LOGS_PATH/$NAME.log.old" 2>/dev/null
		Execute >"$LOGS_PATH/$NAME.log" 2>>"$LOGS_PATH/$NAME".log &
		PID=$!
		disown

		STATUS=$(Status)

		echo "$PID" >"$PID_PATH/$NAME".pid

		if [ "$STATUS" == "ok" ]; then
			echo -e "OK $PID"
		else
			echo "FAIL $(Status.Message)"
		fi
	else
		echo "Error: Unit $1 does not exist."
	fi
}

_kill() {
	internal.Prepare

	if file.Exists "$UNIT_PATH/$1"; then
		source "${UNIT_PATH}/$1"
		PID_FILE="$PID_PATH/$NAME.pid"
		if file.Exists "$PID_FILE"; then
			PID=$(cat "$PID_FILE")

			if process.isAlive "$PID"; then
				kill -9 "$PID"
				echo "KILL ${PID}"
				rm "$PID_FILE"
				echo "RM ${PID_FILE}"
			fi
		else
			echo "Error: Service ins't running."
		fi
	else
		echo "Error: Unit $1 does not exist."
	fi
}

_cat() {
	internal.Prepare

	if file.Exists "$UNIT_PATH/$1"; then
		source "${UNIT_PATH}/$1"
		LOG_FILE="$LOGS_PATH/$NAME.log"
		if file.Exists "$LOG_FILE"; then
			tail -f "$LOG_FILE"
		else
			echo "Error: Log file doesn't exists."
		fi
	else
		echo "Error: Unit $1 does not exist."
	fi
}

_stat() {
	internal.Prepare

	if [ "$1" = "" ]; then

		for file in "$PID_PATH"/*.pid; do
			PID=$(cat "$file")

			if process.isAlive "$PID"; then
				echo "Alive: ${PID}"
			else
				echo "Died: $PID}"
			fi

		done
		return 0
	fi

	if file.Exists "$UNIT_PATH/$1"; then
		source "${UNIT_PATH}/$1"
		echo "${NAME} - ${DESCRIPTION}"
		PID_FILE="$PID_PATH/$NAME.pid"
		LOG_FILE="$LOGS_PATH/$NAME.log"

		if file.Exists "$PID_FILE"; then
			PID=$(cat "$PID_FILE")
			if process.isAlive "$PID"; then
				STAT=$(process.Stat "$PID")
				MEM=$(echo "$STAT" | awk '{ print $2 }')
				CPU=$(echo "$STAT" | awk '{ print $3 }')
				ELAPSED=$(echo "$STAT" | awk '{ print $4 }')

				echo "  Pid: ${PID}"
				echo "  CPU: ${CPU}%"
				echo "  Status: $(Status) $(Status.Message)"
				echo "  Running: ${ELAPSED}"
				echo "  Memory: ${MEM} kB"
				echo
			fi

		fi

		if file.Exists "$LOG_FILE"; then
			echo "Last 50 lines of log"
			head -n50 <"$LOG_FILE"
		fi
	else
		echo "Error: Unit $1 does not exist."
	fi
}

case "$1" in
start) shift && _start "$@" ;;
kill) shift && _kill "$@" ;;
cat) shift && _cat "$@" ;;
stat) shift && _stat "$@" ;;
*)
	echo "services - $VERSION"
	echo "by $AUTHORS"
	echo "Pid Path: ""$PID_PATH"
	echo "Unit Path: $UNIT_PATH"
	echo "Base Path: $BASE_PATH"
	echo "USAGE:"
	echo "  kill  <UNIT NAME> - kill a service"
	echo "  start <UNIT NAME> - start a service"
	echo "  stat  [UNIT NAME] - stat a service or list services and theirs states."
	echo "  cat   <UNIT NAME> - tails log file of UNIT"
	;;
esac
