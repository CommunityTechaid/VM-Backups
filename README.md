# VM Backup Script

Simplish script for generating stand alone backup images of all the VMs running.

## Install

- Copy `VM-Backup-Script.sh` to `/usr/local/bin`.
- Copy `VM-Backup.service` and `VM-Backup.timer` to `/etc/systemd/system`
- Reload systemd file with `systemctl daemon-reload`
- Start and enable the timer with `systemctl enable --now VM-Backup.timer`


## Testing Backups

- Move to the location of the images.
- Run: ```bash
sudo qemu-system-x86_64 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_VARS.fd \
  -drive file=./WindowsServer-202501221737551255.qcow2,format=qcow2 \
  -m 16384 -M q35 -smp 4```
	- The `-drive if=pflash...` arguments defines the UEFI / TianaCore BIOS.
	- The `-drive=file...` argument points to the image to boot.
	- The `-m` set how much RAM to grant to the VM.
	- The `-M` sets the machine type to emulate.
	- `-smp` sets how many vCPUs to allocate to the VM.
