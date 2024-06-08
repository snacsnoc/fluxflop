#!/bin/bash
cd root/
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../rootfs.cpio.gz
# Optional:
# cp rootfs.cpio.gz ../bootable_image/boot
