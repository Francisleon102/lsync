#!/bin/bash
HOST=("169.254.21.226" )
SRC="/home/leon/Music"
DEST="/home/francis/Music"
USER="francis"
EVENTS="create,modify,delete,attrib"
PING_CMD=(ping -c 1 -W 2 "$HOST")
INOTIFY_CMD=(inotifywait -q -e "$EVENTS" "$SRC")
NOTIFY=($"PINGNOTIFY" $"INOTIFY_CMD")
LOG=('--log-file=/var/log/rsync.log --log-file-format="%t %o %n%L"')
KEYID=
ok=0



while "${INOTIFY_CMD[@]}" ; do 
Date=$(date "+%Y-%m-%d %H:%M:%S")

	f "${PING_CMD[@]}" > /dev/null 2>&1; then  #chech if host is up 
    echo "✅ Host $HOST is reachable"
    rsync -avz --progress --delete "$LOG" "$SRC/"  "$USER@$HOST:$DEST/"
    echo "Sync $HOST done ✅ at $Date "
    sleep 5
	else
    echo "❌ Host $HOST is down — Not updated "
      	sleep 5
      	ok=1

    fi
   until "${PING_CMD[@]}" > /dev/null 2>&1; do
           echo "❌ Host down — retrying in 5s"
           sleep 10
           
    done
    if((ok)); then
  echo "✅ Host $HOST back up — syncing all changes since last push…"
  rsync -avz --progress "$SRC/" "$USER@$HOST:$DEST/"
  echo "✅ Sync to $HOST done at $(date '+%Y-%m-%d %H:%M:%S')"
  ok=0
     fi

done 







