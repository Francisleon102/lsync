#!/bin/bash
HOST=("169.254.21.226" )
SRC="/home/leon/Music"
DEST="/home/francis/Music"
USER="francis"


while inotifywait -q -e create,modify,delete,attrib "$SRC"; do 
Date=$(date "+%Y-%m-%d %H:%M:%S")

if ping -c 1 -W 2 $HOST > /dev/null 2>&1; then  #chech if host is up 
    echo "✅ Host $HOST is reachable"
    rsync -avz --progress "$SRC/" "$USER@$HOST:$DEST/"
    echo "Sync $HOST done ✅ at $Date "
    
else
    echo "❌ Host $HOST is down — Not updated  "
    for i in {1..5}; do
      echo "retry in $i" 
    done
      
       rsync -avz --progress "$SRC/" "$USER@$HOST:$DEST/"
    echo "Sync $HOST done ✅ at $Date "
    
    
   
fi
done 
