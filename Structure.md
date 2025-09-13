Got it ✅ Let’s recap everything you worked through tonight so you can pick it up cleanly next time.

---

# 📌 Progress Tonight

### 🔧 **rsync basics & automation**

* Learned `rsync` is **one-way** (source → destination).
* Push:

  ```bash
  rsync -avz /local/path/ user@host:/remote/path/
  ```
* Pull:

  ```bash
  rsync -avz user@host:/remote/path/ /local/path/
  ```
* Useful flags:

  * `-a` archive (preserves perms/times/etc.)
  * `-z` compress
  * `-v` verbose
  * `--progress` show progress
  * `--delete` mirror exactly (removes extras)
  * `-u` / `--update` skip newer files on dest

---

### 🔧 **inotify-tools**

* `inotifywait` waits for file changes.
* `-e` filters events: `create, modify, delete`.
* `-m` keeps watching forever.
* Used with loop to trigger rsync:

  ```bash
  while inotifywait -q -e create,modify,delete /src; do
      rsync -avz /src/ user@host:/dst/
  done
  ```
* Resource-friendly (kernel events, not busy loop).

---

### 🔧 **Background jobs & daemons**

* `&` → runs a command in the background, but only once.
* `nohup` / `screen` / `tmux` → keep running after logout.
* `systemd service` → proper daemon:

  ```ini
  [Unit]
  Description=Sync daemon
  After=network-online.target
  Wants=network-online.target

  [Service]
  User=leon
  ExecStart=/home/leon/Lsyncc.sh
  Restart=always

  [Install]
  WantedBy=multi-user.target
  ```
* Logs go to `journalctl -u service-name -f`.

---

### 🔧 **Networking & IPs**

* Get LAN IPs:

  ```bash
  hostname -I
  ```
* Get public IP:

  ```bash
  curl ifconfig.me
  ```
* Store in variable:

  ```bash
  IP=$(hostname -I | awk '{print $1}')
  ```
* Count:

  ```bash
  hostname -I | wc -w   # number of IPs
  hostname -I | wc -m   # characters
  ```

---

### 🔧 **Bash scripting**

* Variables:

  ```bash
  HOST="192.168.0.110"
  ```
* If + ping check:

  ```bash
  if ping -c 1 -W 2 $HOST >/dev/null 2>&1; then
      echo "✅ Host is reachable"
  else
      echo "❌ Host is down"
  fi
  ```
* `2>&1` → redirects stderr to stdout.
* Fixed script (`Lsyncc.sh`) to echo messages properly instead of failing.

---

### 🔧 **tmux**

* Create sessions:

  ```bash
  tmux new -s session1
  tmux new -s session2
  ```
* Split panes:

  * `Ctrl+b %` → vertical split
  * `Ctrl+b "` → horizontal split
* Navigate with `Ctrl+b + arrow keys`.

---

# ✅ Where to Continue Next Time

IP automatic Configurations
config files 
