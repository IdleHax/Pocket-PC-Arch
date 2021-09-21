#!/bin/bash

# Script to automatically generate an iso for installing to an SD using the latest software available (at least it will lol)
# Be sure to run this in a new, empty directory each time or it could possibly frag your machine.
# all modified directories in the script are defined as local to make it harder to break things if you didnt follow the last step...
# do not run this if you have any mounted loopback devices, it would probably just unmount them first but no point in risking it.
# you can check this with losetup -a
# I recommend just running this in a kali vm, since that's what i did (my life is in shambles don't ask why) as all the dependancies are in their repos for sure, and you can't break your system.
#
# this was inspired by the work of the Danctnix team, and Danct12
#

#delete source dirs and files to clean up runs, i guess
sudo rm -rf ./iso_mnt
sudo rm -rf ./source
#create a dir if it isnt there
mkdir -p ./source
#download if file on server is newer than local, into specified dir
sudo wget -N http://archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz -P ./source
#install tools if missing
sudo apt install proot qemu-user-static bsdtar
#remove existing loopbacks
sudo losetup -D
#create dir for loopback file to live in
mkdir -p ./iso_mnt
#create loopback device to get hands dirty
dd if=/dev/zero of=./iso_mnt/loopbackfile.img bs=1M count=2000
sudo losetup -fP ./iso_mnt/loopbackfile.img
(
echo o # Create a new empty DOS partition table
echo n # Primary partition
echo p # Partition number
echo 1 # First sector (Accept default: 1)
echo 4096 # first sector begins after uboot :)
echo   # Last sector (Accept default: varies)
echo w # Write changes
) | sudo fdisk
sudo fdisk /dev/loop0
#create ext4 fs on loopback device
mkfs.ext4 -F /dev/loop0
mkdir ./root
sudo mount /dev/loop0 root
#extract default armv8 image to partitioned loopback device
bsdtar -xpf ./source/ArchLinuxARM-aarch64-latest.tar.gz -C root
#Download the boot.scr script for U-Boot and place it in the /boot directory
sudo wget http://os.archlinuxarm.org/os/allwinner/boot/pine64/boot.scr -O root/boot/boot.scr
#Unmount the partition
sudo umount root
#Download and install the U-Boot bootloader (points to generic non-PocketPC uboot right this second)
sudo wget -N http://os.archlinuxarm.org/os/allwinner/boot/pine64/u-boot-sunxi-with-spl.bin -P ./source
dd if=./source/u-boot-sunxi-with-spl.bin of=/dev/loop0 bs=8k seek=1
#from here we have to chroot into our loopback device and complete the setup as listed here https://archlinuxarm.org/platforms/armv8/allwinner/pine64
#a guide to the chroot process lives here https://archlinuxarm.org/forum/viewtopic.php?f=30&t=9294
#next steps are installing the drivers and arch repo packages.
#from there we just have to make an iso of the loopback device
#I used filezilla instead of like, dd to make the .iso last time for some reason, I don't remember why, we cant keep things automatic this way