#!/bin/bash
# NetHunter kernel for Samsung Galaxy S7 build script by jcadduono

################### BEFORE STARTING ################
#
# download a working toolchain and extract it somewhere and configure this
# file to point to the toolchain's root directory.
#
# once you've set up the config section how you like it, you can simply run
# ./build.sh [VARIANT]
#
##################### VARIANTS #####################
#
# xx   = International Exynos & Duos, Canadian Exynos
#        SM-G930F, SM-G930FD, SM-G930X, SM-G930W8
#        SM-G935F, SM-G935FD, SM-G935X, SM-G935W8
#
# kor  = Korean Exynos
#        SM-G930K, SM-G930L, SM-G930S
#
###################### CONFIG ######################

# root directory of NetHunter herolte git repo (default is this script's location)
RDIR=$(pwd)

[ "$VER" ] ||
# version number
VER=$(cat "$RDIR/VERSION")

# directory containing cross-compile arm64 toolchain
TOOLCHAIN=/home/test/Kali_Kernel/linaro-64/bin

# amount of cpu threads to use in kernel make process
THREADS=5

############## SCARY NO-TOUCHY STUFF ###############

export ARCH=arm64
export CROSS_COMPILE=$TOOLCHAIN/aarch64-linux-android-

[ "$DEVICE" ] || DEVICE=hero2lte
[ "$TARGET" ] || TARGET=nethunter
[ "$1" ] && VARIANT=$1
[ "$VARIANT" ] || VARIANT=xx

DEFCONFIG=${TARGET}_defconfig
DEVICE_DEFCONFIG=device_${DEVICE}_defconfig
VARIANT_DEFCONFIG=variant_${VARIANT}_defconfig

ABORT()
{
	echo "Error: $*"
	exit 1
}

[ -f "$RDIR/arch/$ARCH/configs/${DEFCONFIG}" ] ||
abort "Config $DEFCONFIG not found in $ARCH configs!"

[ -f "$RDIR/arch/$ARCH/configs/$DEVICE_DEFCONFIG" ] ||
abort "Device $DEVICE not found in $ARCH configs!"

[ -f "$RDIR/arch/$ARCH/configs/$VARIANT_DEFCONFIG" ] ||
abort "Device variant/carrier $VARIANT not found in $ARCH configs!"

export LOCALVERSION=$TARGET-$DEVICE-$VARIANT-$VER

CLEAN_BUILD()
{
	echo "Cleaning build..."
	cd "$RDIR"
	rm -rf build
}

SETUP_BUILD()
{
	echo "Creating kernel config for $LOCALVERSION..."
	cd "$RDIR"
	mkdir -p build
	make -C "$RDIR" O=build "$DEFCONFIG" \
		DEVICE_DEFCONFIG="$DEVICE_DEFCONFIG" \
		VARIANT_DEFCONFIG="$VARIANT_DEFCONFIG" \
		|| ABORT "Failed to set up build"
}

BUILD_KERNEL()
{
	echo "Starting build for $LOCALVERSION..."
	while ! make -C "$RDIR" O=build -j"$THREADS"; do
		read -p "Build failed. Retry? " do_retry
		case $do_retry in
			Y|y) continue ;;
			*) return 1 ;;
		esac
	done
}

BUILD_DTB()
{
	echo "Generating dtb.img..."
	cd "$RDIR"
	DEVICE=$DEVICE ./dtbgen.sh $VARIANT || ABORT "Failed to generate dtb.img!"
}

CLEAN_BUILD && SETUP_BUILD && BUILD_KERNEL && BUILD_DTB && echo "Finished building $LOCALVERSION!"
