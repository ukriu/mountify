#!/bin/sh
# customize.sh
# this script is part of mountify
# No warranty.
# No rights reserved.
# This is free software; you can redistribute it and/or modify it under the terms of The Unlicense.
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH

# some bullshit just to use clear
if [ "$MMRL" = "true" ] || { [ "$KSU" = "true" ] && [ "$KSU_VER_CODE" -ge 11998 ]; } || 
	{ [ "$KSU_NEXT" = "true" ] && [ "$KSU_VER_CODE" -ge 12144 ]; } ||
	{ [ "$APATCH" = "true" ] && [ "$APATCH_VER_CODE" -ge 11022 ]; }; then
	clear
        loops=20
        while [ $loops -gt 1 ];  do 
		for i in '[-]' '[/]' '[|]' '[\]'; do 
		        echo "$i"
		        sleep 0.1
		        clear
		        loops=$((loops - 1)) 
		done
        done
else
	# sleep a bit to make it look like something is happening!!
	sleep 2
fi

# theres reports that it bootloops on certain devices
# split it from top condition for readability
if getprop ro.product.name | grep -q 'vermeer' ; then
	echo "[!] Configuring System..."
	# confuse the uninitiated
	time dd if=/dev/zero of=/dev/null bs=1M count=20000 2>&1
	abort "[!] Installation failed as device \"vermeer\" is not supported"
fi

# routine start

echo "[+] mountify"
echo "[+] SysReq test"
# test for overlayfs
if grep -q "overlay" /proc/filesystems > /dev/null 2>&1; then \
	echo "[+] CONFIG_OVERLAY_FS"
	echo "[+] overlay found in /proc/filesystems"
else
	abort "[!] CONFIG_OVERLAY_FS is required for this module!"
fi

# test for tmpfs xattr
[ -w /mnt ] && MNT_FOLDER=/mnt
[ -w /mnt/vendor ] && MNT_FOLDER=/mnt/vendor
testfile="$MNT_FOLDER/tmpfs_xattr_testfile"
rm $testfile > /dev/null 2>&1 
busybox mknod "$testfile" c 0 0 > /dev/null 2>&1 
if busybox setfattr -n trusted.overlay.whiteout -v y "$testfile" > /dev/null 2>&1 ; then 
	echo "[+] CONFIG_TMPFS_XATTR"
	echo "[+] tmpfs extended attribute test passed"
else
	rm $testfile > /dev/null 2>&1 
	abort "[!] CONFIG_TMPFS_XATTR is required for this module!"
fi
rm $testfile > /dev/null 2>&1 

# grab version code
module_prop="/data/adb/modules/mountify/module.prop"
if [ -f $module_prop ]; then
	mountify_versionCode=$(grep versionCode $module_prop | sed 's/versionCode=//g' )
else
	mountify_versionCode=0
fi

# replace if 129 and older
# https://github.com/backslashxx/mountify/commit/caa2cfa1058e1f428e47047d057fa73fed3351ca
if [ $mountify_versionCode -gt 129 ]; then
	configs="modules.txt whiteouts.txt config.sh skipped_modules"
else
	echo "[!] config.sh will be replaced!"
	configs="modules.txt whiteouts.txt"
fi

for file in $configs; do
	if [ -f "/data/adb/modules/mountify/$file" ]; then
		echo "[+] migrating $file"
		cat "/data/adb/modules/mountify/$file" > "$MODPATH/$file"
	fi
done

# warn on OverlayFS managers
# while this is supported (half-assed), this is not a recommended configuration
if { [ "$KSU" = true ] && [ ! "$KSU_MAGIC_MOUNT" = true ]; } || { [ "$APATCH" = true ] && [ ! "$APATCH_BIND_MOUNT" = true ]; }; then
	printf "\n\n"
	echo "[!] WARNING: Root manager is NOT on magic mount."
	echo "[!] This setup can cause issues and is NOT recommended."
fi

# EOF
