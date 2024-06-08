#!/bin/bash


TOYBOX_BIN="toybox-i486"

# List of toybox commands (from ARM64 version)
COMMANDS=(
acpi arch ascii base32 base64 basename bash blkdiscard blkid blockdev bunzip2 bzcat cal
cat chattr chgrp chmod chown chroot chrt chvt cksum clear cmp comm count cp cpio crc32
cut date dd deallocvt devmem df dirname dmesg dnsdomainname dos2unix du echo egrep eject
env expand factor fallocate false fgrep file find flock fmt fold free freeramdisk fsfreeze
fstype fsync ftpget ftpput getconf getopt gpiodetect gpiofind gpioget gpioinfo gpioset
grep groups gunzip halt head help hexedit host hostname httpd hwclock i2cdetect i2cdump
i2cget i2cset i2ctransfer iconv id ifconfig inotifyd insmod install ionice iorenice iotop
kill killall killall5 link linux32 ln logger login logname losetup ls lsattr lsmod lspci
lsusb makedevs mcookie md5sum memeater microcom mix mkdir mkfifo mknod mkpasswd mkswap
mktemp modinfo mount mountpoint mv nbd-client nbd-server nc netcat netstat nice nl nohup
nproc nsenter od oneit openvt partprobe paste patch pgrep pidof ping ping6 pivot_root pkill
pmap poweroff printenv printf prlimit ps pwd pwdx pwgen readahead readelf readlink realpath
reboot renice reset rev rfkill rm rmdir rmmod route rtcwake sed seq setfattr setsid sh sha1sum
sha224sum sha256sum sha384sum sha3sum sha512sum shred shuf sleep sntp sort split stat strings
su swapoff swapon switch_root sync sysctl tac tail tar taskset tee test time timeout top
touch toysh true truncate ts tsort tty tunctl uclampset ulimit umount uname unicode uniq
unix2dos unlink unshare uptime usleep uudecode uuencode uuidgen vconfig vmstat w watch
watchdog wc wget which who whoami xargs xxd yes zcat
)

BIN_DIR="./root/bin"
USR_BIN_DIR="./root/usr/bin"
USR_SBIN_DIR="./root/usr/sbin"
SBIN_DIR="./root/sbin"

mkdir -p "$BIN_DIR" "$USR_BIN_DIR" "$USR_SBIN_DIR" "$SBIN_DIR"

create_symlink() {
  local cmd=$1
  if [[ "$cmd" =~ ^(halt|ifconfig|insmod|losetup|modinfo|poweroff|reboot|route|rmmod|swapoff|swapon|switch_root|sysctl)$ ]]; then
    ln -sf "../../bin/$TOYBOX_BIN" "$SBIN_DIR/$cmd"
  elif [[ "$cmd" =~ ^(chroot|freeramdisk|i2cdetect|i2cdump|i2cget|i2cset|i2ctransfer|rtc)$ ]]; then
    ln -sf "../../bin/$TOYBOX_BIN" "$USR_SBIN_DIR/$cmd"
  elif [[ "$cmd" =~ ^(login|sh)$ ]]; then
    ln -sf "./$TOYBOX_BIN" "$BIN_DIR/$cmd"
  else
    ln -sf "../../bin/$TOYBOX_BIN" "$USR_BIN_DIR/$cmd"
  fi
}

for cmd in "${COMMANDS[@]}"; do
  create_symlink "$cmd"
done

echo "Symlinks created successfully."
