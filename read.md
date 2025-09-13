This project provides a simple way to synchronize files between two folders using Linux tools. It combines:

inotifywait
 → watches for file changes (create/modify/delete).

rsync
 → syncs files efficiently over SSH.

systemd
 → runs the sync in the background as a service.
