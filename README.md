# fluxflop - floppy-sized Linux

It's ~~2024~~ 2025 and floppies are still cool. Maintain that coolness by building your own floppy-sized Linux distro like it's 1999.

This project is buildable by a gcc toolchain provided by your distribution or by building a [musl](https://www.musl-libc.org/) toolchain. For the smallest binaries sizes, musl is recommended.

## Quick Start
Two pre-built bootable floppy images are available in [Releases](https://github.com/snacsnoc/fluxflop/releases):

- **Linux 6.12.9**: Latest kernel build
 ```bash
 qemu-system-i386 -fda fluxflop-linux-6.12.9-boot.img -boot a -m 32
```

- **Linux 4.20.17**: Optimized for real i486DX hardware
 - Minimum requirements:
   - i486DX CPU @ 25MHz+ (SX models not supported)
   - 8MB RAM minimum (16MB recommended)
 - Boots from:
   - Real 1.44MB floppy disk
   - 86Box/PCem with i486DX configuration
   - QEMU with 5-32MB RAM setting

## Building pre-reqs

__gcc-i686 build:__

Packages:
```
apt-get install build-essential gcc-i686-linux-gnu g++-i686-linux-gnu
```

__i486/i686-musl build:__
```
# see README.md within musl-cross-make for all targets
git clone https://github.com/richfelker/musl-cross-make

cd musl-cross-make
make TARGET=i486-linux-musl
make install

```
__arm64-musl build:__
```
make TARGET=aarch64-linux-musl
make install
```
Add the musl toolchain to your path:
`export PATH=~/musl-cross-make/output/bin:$PATH`

__Building on Mac OS:__

Save yourself a headache and use a pre-built toolchain courtesy of [homebrew-macos-cross-toolchains](https://github.com/messense/homebrew-macos-cross-toolchains)
```
brew tap messense/macos-cross-toolchains
# valid targets are aarch64-unknown-linux-musl, arm-unknown-linux-musleabihf
# armv7-unknown-linux-musleabihf, i686-unknown-linux-musl, x86_64-unknown-linux-musl
brew install i686-unknown-linux-musl
```
Install the LLVM linker:
```
brew install lld
```
Install [lkmake](https://github.com/markbhasawut/mac-linux-kdk) to included needed headers files for a successful build:
```
brew tap markbhasawut/markbhasawut
brew -v install markbhasawut/markbhasawut/mac-linux-kdk
```
For the following directions, use `lkmake` in place of `make`

__Create a build dir:__
`mkdir build/`

__Prepare the kernel:__
```
cd build/
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.9.3.tar.xz
tar -xf linux-6.9.3.tar.xz

# see configs/linux for all configs available
# .config - default i686 config
# .config-x86-fb - i486 with framebuffer support
# .config-x86-serial - i486 with serial support
# .config-x86-vga - i486(DX) with VGA

cp ./configs/linux/6.x.x/.config-<config-name> linux-6.9.3/.config
````
The smallest kernel produced is using `.config-x86-fb` (XZ compression) = 592KB


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
mknod -m 666 ./root/dev/tty c 5 0


```

__Output image directories:__
```
mkdir -p bootable_image/{boot,isolinux}
```


## Build
__Linux:__
Note: if you are including the initramfs in `.config` within the built image, build the rootfs first.
```
cd linux-6.9.3
make ARCH=x86 CROSS_COMPILE=i686-linux-gnu- -j8 #use bzImage for x86, Image.gz for arm64. adjust -gnu to -musl as needed
```


__Toybox:__
```
wget https://landley.net/toybox/bin/toybox-i486 -O ./root/bin/toybox-i486
./scripts/toybox-symlinks.sh
```
Toybox provides many common Linux utilities including a shell. For the sake of simplicity, the static builds provided by Toybox is used.
You can optionally compile Toybox yourself:
```
cd build/
wget https://landley.net/toybox/downloads/toybox-0.8.11.tar.gz
tar xvf toybox-0.8.11.tar.gz

cp ../configs/toybox/.config toybox-0.8.11
cd toybox-0.8.11

make CFLAGS="-march=i486 -mtune=i486" LDFLAGS="-static -s" ARCH=x86 CROSS_COMPILE=i486-linux-musl- -j8
make install
cp -R install/* ./root
```


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

# copy config
cp configs/isolinux/isolinux.cfg bootable_image/isolinux
```

## Boot
__Make a bootable ISO:__
```
./scripts/make-iso.sh
```
and boot with:
```
qemu-system-i386 -cdrom out.iso -m 32 -nographic 
```
__Make a bootable floppy:__
If not already set, edit the Linux `.config` and set `CONFIG_INITRAMFS_SOURCE` to your rootfs cpio archive path.
```
cd build/
git clone https://github.com/oerg866/w98qi-tiny-floppy-bootloader

cd w98qi-tiny-floppy-bootloader/

# generate a bootable floppy
bash build.sh ../linux-6.9.3/arch/x86/boot/bzImage disk.img

```
Boot with qemu:
`qemu-system-i386 -fda disk.img`


__Boot with kernel and initial ramdisk with qemu:__
```
qemu-system-i386 -kernel ./linux-6.8.11/arch/x86/boot/bzImage -initrd ./rootfs.cpio.gz -append "init=/init rdinit=/init console=ttyS0,115200n8" -m 32 -nographic
```

or, if you built with simple framebuffer:
```
qemu-system-i386 -kernel ./bzImage -initrd ./rootfs.cpio.gz -append "init=/init rdinit=/init console=tty0" -m 32
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

easto@debian2:/tmp/linux-6.9.3$ stat -c %s vmlinux
1919144

make KCFLAGS="-fomit-frame-pointer" ARCH=x86 CROSS_COMPILE=i686-linux-gnu- bzImage -j8
 
easto@debian-build:~/testing-linux/linux-6.8.11$ ls -ls arch/x86/boot/bzImage 
716 -rw-r--r-- 1 easto easto 729600 May 30 02:30 arch/x86/boot/bzImage

easto@debian2:/tmp/linux-6.9.3$ stat -c %s vmlinux
1886332
```
__-fno-inline-small-functions__:
```
easto@debian2:/tmp/linux-6.9.3$ stat -c %s vmlinux
1919144

make KCFLAGS="-fno-inline-small-functions" ARCH=x86 CROSS_COMPILE=i486-linux-musl- -j8

easto@debian2:/tmp/linux-6.9.3$ stat -c %s vmlinux
1919528
   ````



find largest objects:
```
nm --size-sort --print-size vmlinux | tail -n 20
````
or
using [Bloaty](https://github.com/google/bloaty)
```
bloaty -d symbols -n 100 vmlinux

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
