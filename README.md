## fluxflop - floppy-sized Linux

It's 2024 and floppies are still cool. Maintain that coolness by building your own floppy-sized Linux distro like it's 1999.

This project is buildable by a gcc toolchain provided by your distribution or by building a [musl](https://www.musl-libc.org/) toolchain. For the smallest binaries sizes, musl is recommended.

## Pre-reqs

__gcc-i686 build:__
Package:
```
apt-get install build-essential gcc-i686-linux-gnu g++-i686-linux-gnu
```

__i486/i686-musl build:__
```
git clone https://github.com/richfelker/musl-cross-make
cd musl-cross-make
make TARGET=i486-linux-musl
make install

```
__arm64-musl build:__
```
make TARGET=i486-linux-musl
make install
```
Add the musl toolchain to your path:
`export PATH=~/musl-cross-make/bin:$PATH`


__Prepare the kernel:__
```
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.11.tar.xz
tar -xf linux-6.8.11.tar.xz
cp ./configs/linux/.config linux-6.8.11/.config
````


__Root filesystem layout:__
```
mkdir -p root/{bin,proc,dev,sys,usr}



# Create a simple init script
# or compile tools/init.c and place in root/
cat > root/init <<EOF
#!/bin/sh
# Mount essential filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Start a shell
exec /bin/sh -i 

# Infinite loop to prevent the script from exiting
while true; do
    sleep 1
done
EOF

chmod a+x root/init

# you will need root privileges to make these nodes
mknod -m 660 ./root/dev/console c 5 1
mknod -m 666 ./root/dev/ttyS0 c 4 64
mknod -m 666 ./rootdev/tty c 5 0


```

__Output image directories:__
```
mkdir -p bootable_image/{boot,isolinux}
```


# Build
__Linux:__
```
cd linux-6.8.11
make ARCH=x86 CROSS_COMPILE=i686-linux-gnu- bzImage -j8
```


__Toybox:__
```
wget https://landley.net/toybox/bin/toybox-i486 -O ./root/bin/toybox-i486
./scripts/toybox-symlinks.sh
```
Toybox provides many common Linux utilities including a shell. For the sake of simplicity, the static builds provided by Toybox is used.
You can optionally compile Toybox yourself.


__Strip debug symbols in the root filesystem:__
```
./scripts/stripfs.sh
```



__Make the initramfs:__
```
./scripts/make-cpio.sh
```

__(Optional): Syslinux for ISOs:__
```
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar xvf syslinux-6.03.tar.gz
cd syslinux-6.03

cp syslinux/bios/core/isolinux.bin bootable_image/isolinux
cp syslinux/bios/com32/elflink/ldlinux/ldlinux.c32 bootable_image/isolinux
cp configs/isolinux/isolinux.cfg bootable_image/isolinux
```

## Boot
__Make a bootable ISO:__
```
./scripts/make-cpio.sh
```
and boot with:
```
qemu-system-i386 -cdrom out.iso -m 32 -nographic 
```



__Boot with kernel and initial ramdisk with qemu:__
```
qemu-system-i386 -kernel ./linux-6.8.11/arch/x86/boot/bzImage -initrd ./rootfs.cpio.gz -append "append init=/init rdinit=/init -m 32 -nographic

```

## Extra
Use a simple C program to use as init:
```
gcc -static -o init tools/init.c
```
Use as the initramfs:
```
echo init | cpio -ov --format=newc > initramfs.img
```

__Kernel image comparison with printk support__:

with:
```
stat -c %s arch/arm64/boot/Image
2809864
```

without:
```
stat -c %s arch/arm64/boot/Image
2283528
```

__-fomit-frame-pointer__:
```
easto@debian-build:~/testing-linux/linux-6.8.11$ ls -ls arch/x86/boot/bzImage 
728 -rw-r--r-- 1 easto easto 741888 May 30 02:27 arch/x86/boot/bzImage


 make KCFLAGS="-fomit-frame-pointer" ARCH=x86 CROSS_COMPILE=i686-linux-gnu- bzImage -j8
 
 easto@debian-build:~/testing-linux/linux-6.8.11$ ls -ls arch/x86/boot/bzImage 
716 -rw-r--r-- 1 easto easto 729600 May 30 02:30 arch/x86/boot/bzImage

```

## Resources
https://landley.net/toybox/

https://justine.lol/sizetricks/

https://elinux.org/images/7/72/Linux_tiny.pdf

https://git.openembedded.org/meta-micro/tree/conf

https://elinux.org/Linux_Tiny

https://ops.tips/notes/booting-linux-on-qemu/

https://android.googlesource.com/platform/external/syzkaller/+/HEAD/docs/linux/setup_linux-host_qemu-vm_arm64-kernel.md

https://github.com/ahgamut/superconfigure/?tab=readme-ov-file

https://github.com/buildroot/buildroot/tree/master/board/qemu/aarch64-virt
