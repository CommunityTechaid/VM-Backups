# VM Backup Script

Simplish script for generating stand alone backup images of all the VMs running.

## Install

- Copy `VM-Backup-Script.sh` to `/usr/local/bin`.
- Copy `VM-Backup.service` and `VM-Backup.timer` to `/etc/systemd/system`
- Reload systemd file with `systemctl daemon-reload`
- Start and enable the timer with `systemctl enable --now VM-Backup.timer`
