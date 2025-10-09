#!/bin/bash
# Sync Music folder to remote; enforce local→remote deletes even when offline.

set -o pipefail  # (non-intuitive) fail the script if any pipeline step fails

# -------------------- CONFIG --------------------
HOST="169.254.21.226"                         # Remote host (string is fine; array not needed)
USER="francis"
SRC="/home/leon/Music"                        # Local source
DEST="/home/francis/Music"                    # Remote destination
SSH_KEY="/home/francis/.ssh/id_rsync_dex"     # SSH key for both ssh and rsync

# Which filesystem events to watch. Includes DELETE & DELETE_SELF.
EVENTS="create,modify,delete,attrib"

# (non-intuitive) Use -m (monitor) so inotifywait never exits; --format prints fullpath and event on one line.
# If you need recursion into subdirs, add -r (and ensure relative-path stripping below still works).
INOTIFY_CMD=(inotifywait -q -m -e "$EVENTS" --format '%w%f|%e' "$SRC")

# Connectivity check (fast)
PING_CMD=(ping -c 1 -W 2 "$HOST")

# Queue file for offline DELETE events only (we don’t queue creates/modifies per your request)
LOG_FILE="/tmp/sync_events_delete_only.log"

# (non-intuitive) Track "we were offline and have pending work"
offline_flag=0

# Ensure log file exists
: > "$LOG_FILE"

echo "📡 Monitoring: $SRC"
echo "  Remote: $USER@$HOST:$DEST"
echo "  Offline delete queue: $LOG_FILE"
echo

# -------------------- HELPERS --------------------

# Return a path relative to $SRC (for remote operations)
relpath() {
  local full="$1"
  # (non-intuitive) Remove leading $SRC/ if present; leaves basename otherwise
  local rel="${full#$SRC/}"
  echo "$rel"
}

# Apply queued offline deletes on remote, then clear the queue
replay_offline_deletes() {
  if [[ ! -s "$LOG_FILE" ]]; then
    return 0
  fi

  echo "📜 Found queued deletes. Replaying on remote…"
  while IFS='|' read -r ts _event rel; do
    # (non-intuitive) rel may contain spaces; keep it unmodified
    if [[ -n "$rel" ]]; then
      echo "🗑️  [$ts] Removing remotely: $DEST/$rel"
      ssh -i "$SSH_KEY" "$USER@$HOST" "rm -f \"${DEST%/}/$rel\"" 2>/dev/null || {
        echo "⚠️  Remote delete failed for: $rel (will still be caught by rsync --delete)"
      }
    fi
  done < "$LOG_FILE"

  # Clear the queue after replay
  : > "$LOG_FILE"
  echo "✅ Offline delete queue applied."
}

# Perform a full sync; --delete enforces that files missing locally are removed remotely
full_sync() {
  echo "🔄 Running rsync parity (may remove remote extras)…"
  rsync -e "ssh -i $SSH_KEY" -avz --delete --progress "$SRC/" "$USER@$HOST:$DEST/" || {
    echo "❌ rsync failed."
    return 1
  }
  echo "✅ rsync complete."
}

# -------------------- MAIN LOOP --------------------

# (non-intuitive) Read inotifywait stream line-by-line as "fullpath|EVENTS"
while IFS='|' read -r fullpath events; do
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  if "${PING_CMD[@]}" >/dev/null 2>&1; then
    # --------- ONLINE ---------
    # If we were previously offline, first replay queued deletes then parity sync
    if (( offline_flag )); then
      echo "✅ $HOST is back online @ $ts"
      replay_offline_deletes
      full_sync
      offline_flag=0
    fi

    # Handle current event
    # (non-intuitive) inotifywait may report multiple event tokens: e.g., "DELETE,ISDIR"
    if [[ "$events" == *"DELETE"* ]]; then
      # Compute relative path so we can target remote precisely
      rel="$(relpath "$fullpath")"
      echo "🗑️  [$ts] Local DELETE detected: $rel — remove on remote"
      # Try explicit remote remove for immediate responsiveness…
      ssh -i "$SSH_KEY" "$USER@$HOST" "rm -f \"${DEST%/}/$rel\"" 2>/dev/null || {
        echo "⚠️  Remote rm failed; will rely on rsync --delete."
      }
      # …then run a quick parity sync to catch any missed edges and directories.
      full_sync

    else
      # Non-delete: just sync incremental changes
      echo "📥 [$ts] Event: $events — syncing changes"
      rsync -e "ssh -i $SSH_KEY" -avz --progress "$SRC/" "$USER@$HOST:$DEST/" || {
        echo "❌ rsync failed during incremental sync."
      }
    fi

  else
    # --------- OFFLINE ---------
    echo "❌ Host $HOST unreachable @ $ts"

    # Only record deletes per your request
    if [[ "$events" == *"DELETE"* ]]; then
      rel="$(relpath "$fullpath")"
      echo "$ts|DELETE|$rel" >> "$LOG_FILE"
      echo "🗂️  Queued offline delete: $rel"
    fi

    # (non-intuitive) Mark that we have offline work to reconcile later
    offline_flag=1

    # (non-intuitive) Actively wait here until host returns so we can flush the queue ASAP.
    # We still keep the inotify stream open because the outer loop continues reading events.
    until "${PING_CMD[@]}" >/dev/null 2>&1; do
      sleep 5
    done

    # (non-intuitive) As soon as host is back, replay deletes + parity sync right away
    echo "🔁 Host is back; reconciling offline deletes…"
    replay_offline_deletes
    full_sync
    offline_flag=0
  fi

done < <("${INOTIFY_CMD[@]}")

