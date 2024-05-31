find ./root -print0 | cpio --null -ov --format=newc | gzip -9 > rootfs.cpio.gz
cp rootfs.cpio.gz ../bootable_image/boot
