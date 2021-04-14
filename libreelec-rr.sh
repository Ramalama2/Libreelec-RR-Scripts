#!/bin/bash
#
# Config:
LE_Repo="https://github.com/SupervisedThinking/LibreELEC-RR.git"
LE_Branch="master-rr"
LE_Folder2Use="$HOME/LibreelecRR"

# Do you want to build if everything is done?
LE_BUILD="no"

# Allow non-free Packages?
LE_NON_FREE_PKG_SUPPORT="yes"

# Do you want to disable drivers for a smaller/faster booting Libreelec?
LE_DISABLE_DRIVERS="yes"
# Which drivers you need? Disable with 0!
LE_DRIVER_CPU_AMD=1
LE_DRIVER_CPU_Intel=1
LE_DRIVER_GPU_AMD=0
LE_DRIVER_GPU_Intel=1
LE_DRIVER_GPU_Nvidia=1
LE_DRIVER_DVB=1
LE_DRIVER_BLUETOOTH=1
LE_DRIVER_WIFI=1
LE_DRIVER_FIREWIRE=1


if [[ $(id -u) == 0 ]]; then
	echo "ERROR: Building as root is not supported!"
	exit 1
fi

if [ -d "$LE_Folder2Use" ]; then
	echo "INFO: $LE_Folder2Use update!"
else
	echo "INFO: $LE_Folder2Use initialize!"
	git clone --branch $LE_Branch $LE_Repo $LE_Folder2Use
fi

cd $LE_Folder2Use

if [[ "$LE_NON_FREE_PKG_SUPPORT" == "1" || "$LE_NON_FREE_PKG_SUPPORT" == "yes" ]]; then
#       Enable non-free Support:
	sed -i "s/NON_FREE_PKG_SUPPORT=.*/NON_FREE_PKG_SUPPORT=\"yes\"/g" projects/Generic/options
	echo "INFO: NON_FREE_PKG_SUPPORT enabled!"
fi

function LE_DRIVERS_FUNCTION {
	LE_CONFIG_OPTIONS=()
	# Proof of Concept example, more needs to be implemented.
	if [[ "$LE_DRIVER_GPU_AMD" == "0" ]]; then
		echo "INFO: Disabling AMD GPU!"
		LE_CONFIG_OPTIONS+=( "CONFIG_DRM_RADEON" "CONFIG_DRM_AMDGPU" "CONFIG_DRM_RADEON_USERPTR" "CONFIG_DRM_AMDGPU_SI" "CONFIG_DRM_AMDGPU_CIK" "CONFIG_DRM_AMDGPU_USERPTR" "CONFIG_DRM_AMDGPU_GART_DEBUGFS" \
				"CONFIG_DRM_AMD_ACP" "CONFIG_DRM_AMD_DC" "CONFIG_DRM_AMD_DC_DCN" "CONFIG_DRM_AMD_DC_DCN3_0" "CONFIG_DRM_AMD_DC_HDCP" "CONFIG_DRM_AMD_DC_SI" "CONFIG_HSA_AMD" )
	fi
	if [[ "$LE_DRIVER_GPU_Intel" == "0" ]]; then
		echo "INFO: Disabling Intel GPU!"
	fi
	if [[ "$LE_DRIVER_GPU_Nvidia" == "0" ]]; then
		echo "INFO: Disabling Nvidia GPU!"
	fi
	# etc... etc... etc...

	if [ -z "$LE_CONFIG_OPTIONS" ]; then
		echo "INFO: No Drivers will be disabled!"
	else
		for LE_DISABLE_DRIVER in "${LE_CONFIG_OPTIONS[@]}"; do
			sed -i "s/$LE_DISABLE_DRIVER=.*/$LE_DISABLE_DRIVER=n/g" projects/Generic/linux/linux.x86_64.conf
		done
	fi
}

if [[ "$LE_DISABLE_DRIVERS" == "1" || "$LE_DISABLE_DRIVERS" == "yes" ]]; then
	LE_DRIVERS_FUNCTION
fi
if [[ "$LE_BUILD" == "1" || "$LE_BUILD" == "yes" ]]; then
	PROJECT=Generic ARCH=x86_64 BUILD_PERIODIC=RR BUILDER_NAME=$LE_Branch make image
fi
