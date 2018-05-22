#!/bin/bash
# Copy output of iphone build to versioned binary repository
# Mount network drive, if necessary
# 
# Usage: copyrv.sh <AD_HOC_INPUT_PATH> <APP_STORE_INPUT_PATH> <BASE_OUTPUT_PATH>
# Example: copyrv.sh "build/RealityVision Ad Hoc" "build/RealityVision App Store" "QA_Forward_Hudson_All/v3.0.1.1"
#

ad_hoc_in_path=$1
app_store_in_path=$2
netdrive=rhea_netdrive
base_out_path=~/$netdrive/$3
ad_hoc_out_path=$base_out_path/Ad\ Hoc
app_store_out_path=$base_out_path/App\ Store
ERRORCODE=0
rc=0

if ! df | grep $netdrive ; then
	echo Mounting network drive...
	if ! mount -t smbfs //ccuser:turtlepower@rhea/Builds ~/$netdrive ; then
		echo ERROR: Failed to mount network drive.  Exiting.
		exit 1
	else
		echo Success.
	fi
fi

echo Creating build subdirectories

mkdir -p "$ad_hoc_out_path"
mkdir -p "$app_store_out_path"

echo Copying Ad Hoc *.ipa to network drive...

if ! cp -n "$ad_hoc_in_path"/*.ipa "$ad_hoc_out_path"/RealityVision.ipa ; then
	echo ERROR: Copy Ad Hoc *.ipa failed. Does file already exist?
	rc=1
else
	echo Success.
fi

echo Copying App Store *.ipa to network drive...

if ! cp -n "$app_store_in_path"/*.ipa "$app_store_out_path"/RealityVision.ipa ; then
	echo ERROR: Copy App Store *.ipa failed. Does file already exist?
	rc=1
else
	echo Success.
fi

# Leave disk mounted
#diskutil umount ~/rhea_netdrive

exit $rc

