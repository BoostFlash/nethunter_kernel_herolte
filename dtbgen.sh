#!/bin/bash
# simple bash script for generating dtb image

# directory containing cross-compile arm64 toolchain
TOOLCHAIN=/home/test/Kali_Kernel/linaro-64/bin

# device dependant variables
PAGE_SIZE=2048
DTB_PADDING=0

export ARCH=arm64
export CROSS_COMPILE=$TOOLCHAIN/aarch64-linux-android-

RDIR=$(pwd)
BDIR=$RDIR/build
OUTDIR=$BDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$BDIR/scripts/dtc/dtc
INCDIR=$RDIR/include

ABORT()
{
	echo "Error: $*"
	exit 1
}

[ -f "$DTCTOOL" ] || abort "You need to run ./build.sh first!"

[ "$DEVICE" ] || DEVICE=herolte
[ "$1" ] && VARIANT=$1
[ "$VARIANT" ] || VARIANT=xx

case $DEVICE in
herolte)
	case $VARIANT in
	can|eur|xx|duos)
		DTSFILES="exynos8890-herolte_eur_open_00 exynos8890-herolte_eur_open_01
				exynos8890-herolte_eur_open_02 exynos8890-herolte_eur_open_03
				exynos8890-herolte_eur_open_04 exynos8890-herolte_eur_open_08
				exynos8890-herolte_eur_open_09"
		;;
	kor|skt|ktt|lgt)
		DTSFILES="exynos8890-herolte_kor_all_00 exynos8890-herolte_kor_all_01
				exynos8890-herolte_kor_all_02 exynos8890-herolte_kor_all_03
				exynos8890-herolte_kor_all_04 exynos8890-herolte_kor_all_08"
		;;
	*) abort "Unknown variant: $VARIANT" ;;
	esac
	;;
hero2lte)
	case $VARIANT in
	can|eur|xx|duos)
		DTSFILES="exynos8890-hero2lte_eur_open_00 exynos8890-hero2lte_eur_open_01
				exynos8890-hero2lte_eur_open_03 exynos8890-hero2lte_eur_open_04
				exynos8890-hero2lte_eur_open_08"
		;;
	kor|skt|ktt|lgt)
		DTSFILES="exynos8890-hero2lte_kor_all_00 exynos8890-hero2lte_kor_all_01
				exynos8890-hero2lte_kor_all_03 exynos8890-hero2lte_kor_all_04
				exynos8890-hero2lte_kor_all_08"
		;;
	*) abort "Unknown variant: $VARIANT" ;;
	esac
	;;
*) abort "Unknown device: $DEVICE" ;;
esac

mkdir -p "$OUTDIR" "$DTBDIR"

cd "$DTBDIR" || abort "Unable to cd to $DTBDIR!"

rm -f ./*

echo "Processing dts files..."

for dts in $DTSFILES; do
	echo "=> Processing: ${dts}.dts"
	"${CROSS_COMPILE}cpp" -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
	echo "=> Generating: ${dts}.dtb"
	$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
done

echo "Generating dtb.img..."
"$RDIR/scripts/dtbTool/dtbTool" -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE || exit 1

echo "Done."
