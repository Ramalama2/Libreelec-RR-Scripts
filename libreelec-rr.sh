#!/bin/bash
# Version 1: Simple script to Build LibreELEC-RR 10 by yourself the noob way xD
#
# Config:
LE_Repo="https://github.com/SupervisedThinking/LibreELEC-RR.git"
LE_Branch="master-rr"			# Branch to use, check Libreelec-RR at Github
LE_Folder2Use="$HOME/LibreelecRR"	# Folder that will get used (Workingfolder)
LE_BUILD="yes"				# Automatically initiate the building process
LE_BUILD_BY="Script_v1"			# Just a name, that stays in the buildinfo
LE_BUILD_PLATFORM="x86_64"		# Build for: x86_64 (Generic), RPi4, RK3399
LE_NON_FREE_PKG_SUPPORT="yes"		# Allow non-free Packages? (this enables xow)

# Generic x86_64 Only	## RPi4, RK3399 are already very minimal and optimized, so they dont need an similar section!
LE_TARGET_CPU="core2"	# x86-64, core2, just read this: https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
LE_DISABLE_DRIVERS="no"	# If "no", then everything below will have no function!
LE_DRIVER_CPU_AMD=0	# 0 = Remove driver, 1 = Keep (Default)
LE_DRIVER_CPU_Intel=1
LE_DRIVER_GPU_AMD=0
LE_DRIVER_GPU_Intel=0
LE_DRIVER_GPU_Nvidia=1
LE_DRIVER_VM_GUEST=0
LE_DRIVER_DVB=0
LE_DRIVER_TV_TUNER=0
LE_DRIVER_BLUETOOTH=1
LE_DRIVER_WIFI=1
LE_DRIVER_FIREWIRE=1

### --- This Section is not needed to configure --- ###
# You can define here build dependencies, above the needed command, below in the function, the package that contains it.
LE_BUILD_DEPENDENCIES=( "make" "gcc" "curl" "cabextract" "gdk-pixbuf-pixdata" )
function LE_BUILDENV_PKGHELP { LE_PKG_MSG="INFO: $1 is provided by:"
	if [ -z "$1" ]; then return 0; else case "$1" in
		"gdk-pixbuf-pixdata") echo "$LE_PKG_MSG libgdk-pixbuf2.0-bin"; return 1;;
		"cabextract") echo "$LE_PKG_MSG $1"; return 1;;
		"curl") echo "$LE_PKG_MSG $1"; return 1;;
		# etc... etc... etc...
		*) echo "$LE_PKG_MSG please find yourself!"; return 0;; esac
	fi
}

### --- Code Section --- ###
if [[ -z $(which git) ]]; then echo "ERROR: Please install git first!"; exit 1; fi
if [[ $(id -u) == 0 ]]; then echo "ERROR: Building as root is not supported!"; exit 1; fi
if [ -d "$LE_Folder2Use" ]; then echo "INFO: $LE_Folder2Use update!"; cd $LE_Folder2Use; make clean; git -C $LE_Folder2Use fetch --all; git -C $LE_Folder2Use reset --hard origin/$LE_Branch
else echo "INFO: $LE_Folder2Use initialize!"; git clone --branch $LE_Branch $LE_Repo $LE_Folder2Use; cd $LE_Folder2Use; fi

function LE_DRIVERS_FUNCTION {
	LE_CONFIG_OPTIONS=()
	if [[ "$LE_DRIVER_CPU_Intel" == "0" ]]; then echo "INFO: Disabling Intel CPU Drivers!"
		LE_CONFIG_OPTIONS+=( "CONFIG_INTEL_IOMMU" "CONFIG_INTEL_IOMMU_SVM" )
	fi
	if [[ "$LE_DRIVER_CPU_AMD" == "0" ]]; then echo "INFO: Disabling AMD CPU Drivers!"
		LE_CONFIG_OPTIONS+=( "CONFIG_AMD_IOMMU" "CONFIG_AMD_IOMMU_V2" )
	fi
	if [[ "$LE_DRIVER_GPU_AMD" == "0" ]]; then echo "INFO: Disabling AMD GPU!"
		LE_CONFIG_OPTIONS+=( "CONFIG_DRM_RADEON" "CONFIG_DRM_AMDGPU" "CONFIG_DRM_RADEON_USERPTR" "CONFIG_DRM_AMDGPU_SI" "CONFIG_DRM_AMDGPU_CIK" "CONFIG_DRM_AMDGPU_USERPTR" "CONFIG_DRM_AMDGPU_GART_DEBUGFS" \
				"CONFIG_DRM_AMD_ACP" "CONFIG_DRM_AMD_DC" "CONFIG_DRM_AMD_DC_DCN" "CONFIG_DRM_AMD_DC_DCN3_0" "CONFIG_DRM_AMD_DC_HDCP" "CONFIG_DRM_AMD_DC_SI" "CONFIG_HSA_AMD" )
	fi
	if [[ "$LE_DRIVER_GPU_Intel" == "0" ]]; then echo "INFO: Disabling Intel GPU!"
		LE_CONFIG_OPTIONS+=( "CONFIG_DRM_I915" "CONFIG_DRM_I915_FORCE_PROBE" "CONFIG_DRM_I915_CAPTURE_ERROR" "CONFIG_DRM_I915_COMPRESS_ERROR" "CONFIG_DRM_I915_USERPTR" "CONFIG_DRM_I915_GVT" )
	fi
	if [[ "$LE_DRIVER_GPU_Nvidia" == "0" ]]; then echo "INFO: Disabling Nvidia GPU!"
#		LE_CONFIG_OPTIONS+=( )
	fi
	if [[ "$LE_DRIVER_VM_GUEST" == "0" ]]; then echo "INFO: Disabling Virtual Guest Drivers!"
		LE_CONFIG_OPTIONS+=( "CONFIG_DRM_VMWGFX" "CONFIG_DRM_VMWGFX_FBCON" "CONFIG_DRM_VIRTIO_GPU" "CONFIG_VIRTIO" "CONFIG_VIRTIO_MENU" "CONFIG_VIRTIO_PCI" "CONFIG_VIRTIO_PCI_LEGACY" \
				"CONFIG_VIRTIO_BALLOON" "CONFIG_VIRTIO_INPUT" "CONFIG_VIRTIO_MMIO" "CONFIG_VIRTIO_DMA_SHARED_BUFFER" )
	fi
	if [[ "$LE_DRIVER_DVB" == "0" ]]; then echo "INFO: Disabling DVB Drivers!"
#		LE_CONFIG_OPTIONS+=( "CONFIG_DVB_*" ) # Need to rewrite the drivers function for wildcards -> todo
	fi
	if [[ "$LE_DRIVER_TV_TUNER" == "0" ]]; then echo "INFO: Disabling TV-Tuner Drivers!"
#		LE_CONFIG_OPTIONS+=( "CONFIG_MEDIA_TUNER_*" ) # Need to rewrite the drivers function for wildcards -> todo
	fi

	if [ -z "$LE_CONFIG_OPTIONS" ]; then echo "INFO: No Drivers will be disabled!"
	else
		for LE_DISABLE_DRIVER in "${LE_CONFIG_OPTIONS[@]}"; do
			sed -i "s/$LE_DISABLE_DRIVER=.*/$LE_DISABLE_DRIVER=n/g" projects/Generic/linux/linux.x86_64.conf
		done
	fi
}

case "$LE_BUILD_PLATFORM" in
	"x86_64"|"Generic") LE_P_CONFIG_FILE="projects/Generic/options"
		LE_COMPILE() { PROJECT=Generic ARCH=x86_64 BUILD_PERIODIC=RR BUILDER_NAME=$LE_BUILD_BY make image; }
		if [[ ! -z "$LE_TARGET_CPU" && "$LE_TARGET_CPU" != "x86-64" ]]; then echo "INFO: Target CPU: $LE_TARGET_CPU"; sed -i "s/TARGET_CPU=.*/TARGET_CPU=\"$LE_TARGET_CPU\"/g" $LE_P_CONFIG_FILE; fi
		if [[ "$LE_DISABLE_DRIVERS" == "1" || "$LE_DISABLE_DRIVERS" == "yes" ]]; then LE_DRIVERS_FUNCTION; fi;;
	"RPi4") LE_P_CONFIG_FILE="projects/RPi/devices/RPi4/options"
		LE_COMPILE() { PROJECT=RPi DEVICE=RPi4 ARCH=arm BUILD_PERIODIC=RR BUILDER_NAME=$LE_BUILD_BY make image; };;
	"RK3399") LE_P_CONFIG_FILE="projects/Rockchip/devices/RK3399/options"
		LE_COMPILE() { PROJECT=Rockchip DEVICE=RK3399 ARCH=arm BUILD_PERIODIC=RR BUILDER_NAME=$LE_BUILD_BY make image; };;
	*) echo "ERROR: Platform not Supported!"; exit 1;;
esac

if [[ "$LE_NON_FREE_PKG_SUPPORT" == "1" || "$LE_NON_FREE_PKG_SUPPORT" == "yes" ]]; then
	sed -i "s/NON_FREE_PKG_SUPPORT=.*/NON_FREE_PKG_SUPPORT=\"yes\"/g" $LE_P_CONFIG_FILE
	echo "INFO: NON_FREE_PKG_SUPPORT enabled!"
fi

function LE_BUILDENV_CHECK { LE_B_SUM=()
	for LE_B_PACKAGE in "${LE_BUILD_DEPENDENCIES[@]}"; do
		if [[ -z $(which $LE_B_PACKAGE) ]]; then LE_B_SUM+=( "$LE_B_PACKAGE" ); LE_BUILDENV_PKGHELP $LE_B_PACKAGE; fi
	done
	if [ -z "$LE_B_SUM" ]; then echo "INFO: All Build dependencies available!"; return 1; else echo "ERROR: Missing - ${LE_B_SUM[*]}"; return 0; fi
}

if [[ "$LE_BUILD" == "1" || "$LE_BUILD" == "yes" ]]; then
	if LE_BUILDENV_CHECK; then exit 1; fi
	LE_COMPILE
fi
