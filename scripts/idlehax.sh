#Check for existance of source files and prompt to download them
if [ -d "./depends/sourcefiles" ]
then 
	echo "Source Files Found";
	echo -n "Would you like to re-download? (y/n)";
	read answer
	if [ "$answer" != "${answer#[Yy]}" ]
	then
		./depends/dlsources.sh
	fi
else
	echo "Source Files not found";
	echo -n "Would you like to download them now? (y/n)";
	read answer
    	if [ "$answer" != "${answer#[Yy]}" ]
    	then
		./depends/dlsources.sh
	else
		exit;
	fi

fi
#Offer to install dependancies if user hasnt already
if [ -f "./depends/sourcefiles/installcheck" ]
then
	echo "Dependencies check passed, moving on";
else
	echo "It does not appear that you have checked for dependencies";
	echo -n "Would you like to do so now? (y/n)";
	read answer
	if [ "$answer" != "${answer#[Yy]}" ]
	then
		sudo apt install proot qemu-user-static libarchive-tools git gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
		touch ./depends/sourcefiles/installcheck
	else
		exit;
	fi
fi
#check for mountpoint
if [ -d "./depends/iso_mnt" ]
then
	echo "Mountpoint already exists";
	echo "Checking if it appears to be mounted";
	if find ./depends/iso_mnt -mindepth 1 -maxdepth 1 | read; then
		echo "dir appears to already be mounted, attemping to unmount now";
		sudo umount ./depends/iso_mnt
		if find ./depends/iso_mnt -mindepth 1 -maxdepth 1 | read; then
			echo "Unmounting unsuccessful, Try deleting subfolders in depends directory and trying again"
			echo "Script terminating"
			exit;
		else
			echo "Unmounting successfull, continuing";
		fi 
	else
		echo "Directory does not appear to be mounted, continuing";
	fi
else
	echo "Mountpoint does not yet exist, creating one";
	mkdir ./depends/iso_mnt
fi
# check for loopback devices
if losetup -a | read; then
	echo -n "Loopback devices present, remove them and continue? (y/n)";
	read answer
    	if [ "$answer" != "${answer#[Yy]}" ]
    	then
		sudo losetup -D
		sudo losetup -D
		if losetup -a | read; then
			echo "Could not remove loopback devices, try to remove them manually before restarting";
			echo "Script will now terminate";
		else
			echo "Removal of loopback devices Successful, continuing";
		fi
	else
		exit;
	fi
else
	echo "No loopback devices detected, continuing";
fi
#Remove old loopbackfile.img if present, then create a fresh one 
echo "Searching for old loopback images";
if [ -f "./depends/loopbackfile.img" ]
then
	echo "Old loopback images detected, attempting to remove";
	sudo rm ./depends/loopbackfile.img
	if [ -f "./depends/loopbackfile.img" ]
	then
		echo "Removal of old loopback images was unsuccessful"
		echo "It may be mounted, try to delete /depends/iso_mnt/loopbackfile.img manually";
		echo "Script will now terminate";
		exit;

	fi
else 
	echo "Old images not detected, continuing";
fi
#Images if present were removed, creating a new one and partitioning it
echo "Creating new loopback image";
dd if=/dev/zero of=./depends/loopbackfile.img bs=1M count=2000
echo "Mounting image";
sudo losetup -fP ./depends/loopbackfile.img
echo "Partioning...";
(
echo o # Create a new empty DOS partition table
echo n # Primary partition
echo p # Partition number
echo 1 # First sector (Accept default: 1)
echo 4096 # first sector begins after uboot :)
echo   # Last sector (Accept default: varies)
echo w # Write changes
) | sudo fdisk /dev/loop0
echo "Formatting partition as ext4...";
sudo mkfs.ext4 -F /dev/loop0p1
#Build Uboot with ATF
echo "Building Arm-Trusted-Firmware";
./depends/sourcefiles/arm-trusted-firmware-2.5/atfbuild.sh
#install uboot binary
echo "Mounting filesystem partion..."
#sudo mount -o /dev/loop0p1 ./depends/iso_mnt
