#!/bin/bash

# Created by TroubleChute https://github.com/TCNOco/
# Downloads and installs CUDA.
# To update:
# 1. Grab links from https://developer.nvidia.com/cuda-toolkit-archive
# 2. To update samples, check releases on https://github.com/NVIDIA/cuda-samples/releases
# If this is missing something, please feel free to update

# Note: Keep the latest version of a major release with a simplified version (ie: 12.1.0 and 12.1.1, only 12.1.1 should have 12.1 as an option - So asking for 12.1 installs the latest)

echo "TroubleChute Nvidia CUDA installer for Ubuntu WSL & Ubuntu (https://tc.ht)"
echo "Supported versions <=12.1, >=14.2"
echo "FULL LIST: 12.1 [12.1.0], 12.0 [12.0.1, 12.0.0], 11.8 [11.8.0], 11.7 [11.7.1, 11.7.0], 11.6 [11.6.2, 11.6.1, 11.6.0], 11.5 [11.5.2, 11.5.1, 11.5.0], 11.4 [11.4.4, 11.4.3, 11.4.2, 11.4.1, 11.4.0], 11.3 [11.3.1, 11.3.0], 11.2 [11.2.2, 11.2.1, 11.2.0], 11.1 [11.1.1, 11.1.0], 11.0 [11.0.3, 11.0.2, 11.0.1], 10.1 [10.1.2, 10.1.1, 10.1.0], 10.0 [10.0.0], 9.2, 9.1, 9.0, 8.0 [8.0-ga2, 8.0-ga1], 7.5, 7.0, 6.5 [6.5-64, 6.5-32], 6.0 [6.0-64, 6.0-32], 5.5 [5.5-64, 5.5-32], 5.0 [5.0-64, 5.0-32], 4.2 [4.2-64, 4.2-32], 4.1 [4.1-64, 4.1-32]. Everything <=4.0 is missing downloads on Nvidia's website (https://developer.nvidia.com/cuda-toolkit-archive)"
echo "-----"
echo "Enter a CUDA version to install: "
read cuda

major=$(echo "$cuda" | awk -F '.' '{print $1}')
minor=$(echo "$cuda" | awk -F '.' '{print $2}')

# Perform floating-point comparison using bc
if (( $(echo "$major.$minor >= 9.2" | bc -l) )); then
	echo "Do you want to download and run cuda-samples to test [CUDA >=9.2]? (y/n): "
	read samples
fi

echo $samples

case $cuda in
	"12.1.0" | "12.1" | "12")
		wget https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_530.30.02_linux.run
		sudo sh cuda_12.1.0_530.30.02_linux.run
	;;
	"12.0.1" | "12.0")
		wget https://developer.download.nvidia.com/compute/cuda/12.0.1/local_installers/cuda_12.0.1_525.85.12_linux.run
		sudo sh cuda_12.0.1_525.85.12_linux.run
	;;
	"12.0.0")
		wget https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux.run
		sudo sh cuda_12.0.0_525.60.13_linux.run
	;;
	"11.8.0" | "11.8" | "11")
		wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run
		sudo sh cuda_11.8.0_520.61.05_linux.run
	;;
	"11.7.1" | "11.7")
		wget https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux.run
		sudo sh cuda_11.7.1_515.65.01_linux.run
	;;
	"11.7.0")
		wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux.run
		sudo sh cuda_11.7.0_515.43.04_linux.run
	;;
	"11.6.2" | "11.6")
		wget https://developer.download.nvidia.com/compute/cuda/11.6.2/local_installers/cuda_11.6.2_510.47.03_linux.run
		sudo sh cuda_11.6.2_510.47.03_linux.run
	;;
	"11.6.1")
		wget https://developer.download.nvidia.com/compute/cuda/11.6.1/local_installers/cuda_11.6.1_510.47.03_linux.run
		sudo sh cuda_11.6.1_510.47.03_linux.run
	;;
	"11.6.0")
		wget https://developer.download.nvidia.com/compute/cuda/11.6.0/local_installers/cuda_11.6.0_510.39.01_linux.run
		sudo sh cuda_11.6.0_510.39.01_linux.run
	;;
	"11.5.2" | "11.5")
		wget https://developer.download.nvidia.com/compute/cuda/11.5.2/local_installers/cuda_11.5.2_495.29.05_linux.run
		sudo sh cuda_11.5.2_495.29.05_linux.run
	;;
	"11.5.1")
		wget https://developer.download.nvidia.com/compute/cuda/11.5.1/local_installers/cuda_11.5.1_495.29.05_linux.run
		sudo sh cuda_11.5.1_495.29.05_linux.run
	;;
	"11.5.0")
		wget https://developer.download.nvidia.com/compute/cuda/11.5.0/local_installers/cuda_11.5.0_495.29.05_linux.run
		sudo sh cuda_11.5.0_495.29.05_linux.run
	;;
	"11.4.4" | "11.4")
		wget https://developer.download.nvidia.com/compute/cuda/11.4.4/local_installers/cuda_11.4.4_470.82.01_linux.run
		sudo sh cuda_11.4.4_470.82.01_linux.run
	;;
	"11.4.3")
		wget https://developer.download.nvidia.com/compute/cuda/11.4.3/local_installers/cuda_11.4.3_470.82.01_linux.run
		sudo sh cuda_11.4.3_470.82.01_linux.run
	;;
	"11.4.2")
		wget https://developer.download.nvidia.com/compute/cuda/11.4.2/local_installers/cuda_11.4.2_470.57.02_linux.run
		sudo sh cuda_11.4.2_470.57.02_linux.run
	;;
	"11.4.1")
		wget https://developer.download.nvidia.com/compute/cuda/11.4.1/local_installers/cuda_11.4.1_470.57.02_linux.run
		sudo sh cuda_11.4.1_470.57.02_linux.run
	;;
	"11.4.0")
		wget https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda_11.4.0_470.42.01_linux.run
		sudo sh cuda_11.4.0_470.42.01_linux.run
	;;
	"11.3.1" | "11.3")
		wget https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.19.01_linux.run
		sudo sh cuda_11.3.1_465.19.01_linux.run
	;;
	"11.3.0")
		wget https://developer.download.nvidia.com/compute/cuda/11.3.0/local_installers/cuda_11.3.0_465.19.01_linux.run
		sudo sh cuda_11.3.0_465.19.01_linux.run
	;;
	"11.2.2" | "11.2")
		wget https://developer.download.nvidia.com/compute/cuda/11.2.2/local_installers/cuda_11.2.2_460.32.03_linux.run
		sudo sh cuda_11.2.2_460.32.03_linux.run
	;;
	"11.2.1")
		wget https://developer.download.nvidia.com/compute/cuda/11.2.1/local_installers/cuda_11.2.1_460.32.03_linux.run
		sudo sh cuda_11.2.1_460.32.03_linux.run
	;;
	"11.2.0")
		wget https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux.run
		sudo sh cuda_11.2.0_460.27.04_linux.run
	;;
	"11.1.1" | "11.1")
		wget https://developer.download.nvidia.com/compute/cuda/11.1.1/local_installers/cuda_11.1.1_455.32.00_linux.run
		sudo sh cuda_11.1.1_455.32.00_linux.run
	;;
	"11.1.0")
		wget https://developer.download.nvidia.com/compute/cuda/11.1.0/local_installers/cuda_11.1.0_455.23.05_linux.run
		sudo sh cuda_11.1.0_455.23.05_linux.run
	;;
	"11.0.3" | "11.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda_11.0.3_450.51.06_linux.run
		sudo sh cuda_11.0.3_450.51.06_linux.run
	;;
	"11.0.2")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_450.51.05_linux.run
		sudo sh cuda_11.0.2_450.51.05_linux.run
	;;
	"11.0.1")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_450.36.06_linux.run
		sudo sh cuda_11.0.1_450.36.06_linux.run
	;;
	"10.2")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.download.nvidia.com/compute/cuda/10.2/prod/local_installers/cuda_10.2.89_440.33.01_linux.run
		sudo sh cuda_10.2.89_440.33.01_linux.run
	;;
	"10.1.2" | "10.1")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.download.nvidia.com/compute/cuda/10.1/prod/local_installers/cuda_10.1.243_418.87.00_linux.run
		sudo sh cuda_10.1.243_418.87.00_linux.run
	;;
	"10.1.1")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.nvidia.com/compute/cuda/10.1/prod/local_installers/cuda_10.1.168_418.67_linux.run
		sudo sh cuda_10.1.168_418.67_linux.run
	;;
	"10.1.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.nvidia.com/compute/cuda/10.1/prod/local_installers/cuda_10.1.105_418.39_linux.run
		sudo sh cuda_10.1.105_418.39_linux.run
	;;
	"10.0.0" | "10.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "please note there is a 'patch 1' that will install after the main install completes."
		wget https://developer.nvidia.com/compute/cuda/10.0/prod/local_installers/cuda_10.0.130_410.48_linux
		sudo sh cuda_10.0.130_410.48_linux
		
		wget http://developer.download.nvidia.com/compute/cuda/10.0/prod/patches/1/cuda_10.0.130.1_linux.run
		sudo sh cuda_10.0.130.1_linux.run
	;;
	"9.2")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "please note there is a 'patch 1' that will install after the main install completes."
		wget https://developer.nvidia.com/compute/cuda/9.2/prod2/local_installers/cuda_9.2.148_396.37_linux -o cuda-9-2.run
		sudo sh cuda-9-2.run
		
		wget https://developer.nvidia.com/compute/cuda/9.2/prod2/patches/1/cuda_9.2.148.1_linux -o cuda-9-2-patch-1.run
		sudo sh cuda-9-2-patch-1.run
	;;
	"9.1")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "please note there are 'patches' that will install after the main install completes. for 9.1 there are 3 patches."
		wget https://developer.nvidia.com/compute/cuda/9.1/prod/local_installers/cuda-repo-ubuntu1704-9-1-local_9.1.85-1_amd64 -o cuda-9-1.run
		sudo sh cuda-9-1.run
		
		wget https://developer.nvidia.com/compute/cuda/9.1/prod/patches/1/cuda-repo-ubuntu1704-9-1-local-cublas-performance-update-1_1.0-1_amd64 -o cuda-9-1-patch-1.run
		sudo sh cuda-9-1-patch-1.run
		
		wget https://developer.nvidia.com/compute/cuda/9.1/prod/patches/2/cuda-repo-ubuntu1704-9-1-local-compiler-update-1_1.0-1_amd64 -o cuda-9-1-patch-2.run
		sudo sh cuda-9-1-patch-2.run	
		
		wget https://developer.nvidia.com/compute/cuda/9.1/prod/patches/3/cuda-repo-ubuntu1704-9-1-local-cublas-performance-update-3_1.0-1_amd64 -o cuda-9-1-patch-3.run
		sudo sh cuda-9-1-patch-3.run
	;;
	"9.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "please note there are 'patches' that will install after the main install completes. for 9.0 there are 4 patches."
		wget https://developer.nvidia.com/compute/cuda/9.0/prod/local_installers/cuda-repo-ubuntu1704-9-0-local_9.0.176-1_amd64-deb -o cuda-repo-ubuntu1704-9-0-local_9.0.176-1_amd64-deb.run
		sudo sh cuda-repo-ubuntu1704-9-0-local_9.0.176-1_amd64-deb.run
		
		wget https://developer.nvidia.com/compute/cuda/9.0/prod/patches/1/cuda-repo-ubuntu1704-9-0-local-cublas-performance-update_1.0-1_amd64-deb -o cuda-9-0-patch-1.run
		sudo sh cuda-9-0-patch-1.run
		
		wget https://developer.nvidia.com/compute/cuda/9.0/prod/patches/2/cuda-repo-ubuntu1704-9-0-local-cublas-performance-update-2_1.0-1_amd64-deb -o cuda-9-0-patch-2.run
		sudo sh cuda-9-0-patch-2.run
		
		wget https://developer.nvidia.com/compute/cuda/9.0/prod/patches/3/cuda-repo-ubuntu1704-9-0-local-cublas-performance-update-3_1.0-1_amd64-deb -o cuda-9-0-patch-3.run
		sudo sh cuda-9-0-patch-3.run
		
		wget https://developer.nvidia.com/compute/cuda/9.0/prod/patches/4/cuda-repo-ubuntu1704-9-0-176-local-patch-4_1.0-1_amd64-deb -o cuda-9-0-patch-4.run
		sudo sh cuda-9-0-patch-4.run		
	;;
	"8.0-ga2" | "8.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "please note there are 'patches' that will install after the main install completes. for 9.0 is 1 patch."
		wget https://developer.nvidia.com/compute/cuda/8.0/prod2/local_installers/cuda_8.0.61_375.26_linux-run -o cuda8-0-ga2.run
		sudo sh cuda8-0-ga2.run
		
		wget https://developer.nvidia.com/compute/cuda/8.0/prod2/patches/2/cuda_8.0.61.2_linux-run -o cuda-8-0-ga2-patch-2.run
		sudo sh cuda-8-0-ga2-patch-2.run
	;;
	"8.0-ga1")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda_8.0.44_linux-run -o cuda-8-0.run
		sudo sh cuda-8-0.run
	;;
	"7.5")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/7.5/prod/local_installers/cuda_7.5.18_linux.run
		sudo sh cuda_7.5.18_linux.run
	;;
	"7.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/7_0/prod/local_installers/cuda_7.0.28_linux.run
		sudo sh cuda_7.0.28_linux.run
	;;
	"6.5-64" | "6.5")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/cuda_6.5.14_linux_64.run
		sudo sh cuda_6.5.14_linux_64.run
	;;
	"6.5-32")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/cuda_6.5.14_linux_32.run
		sudo sh cuda_6.5.14_linux_32.run
	;;
	"6.0-64" | "6.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/6_0/rel/installers/cuda_6.0.37_linux_64.run
		sudo sh cuda_6.0.37_linux_64.run
	;;
	"6.0-32")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/6_0/rel/installers/cuda_6.0.37_linux_32.run
		sudo sh cuda_6.0.37_linux_32.run
	;;
	"5.5-64" | "5.5")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/5_5/rel/installers/cuda_5.5.22_linux_64.run
		sudo sh cuda_5.5.22_linux_64.run
	;;
	"5.5-32")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/5_5/rel/installers/cuda_5.5.22_linux_32.run
		sudo sh cuda_5.5.22_linux_32.run
	;;
	"5.0-64" | "5.0")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/5_0/rel-update-1/installers/cuda_5.0.35_linux_64_ubuntu11.10-1.run
		sudo sh cuda_5.0.35_linux_64_ubuntu11.10-1.run
	;;
	"5.0-32")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		wget http://developer.download.nvidia.com/compute/cuda/5_0/rel-update-1/installers/cuda_5.0.35_linux_32_ubuntu11.10-1.run
		sudo sh cuda_5.0.35_linux_32_ubuntu11.10-1.run
	;;
	"4.2-64" | "4.2")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "for versions this old, the sdk is seperate and will install after the cuda toolkit completes."
		wget http://developer.download.nvidia.com/compute/cuda/4_2/rel/toolkit/cudatoolkit_4.2.9_linux_64_ubuntu11.04.run
		sudo sh cudatoolkit_4.2.9_linux_64_ubuntu11.04.run
		
		wget http://developer.download.nvidia.com/compute/cuda/4_2/rel/sdk/gpucomputingsdk_4.2.9_linux.run
		sudo sh gpucomputingsdk_4.2.9_linux.run
	;;
	"4.2-32")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "for versions this old, the sdk is seperate and will install after the cuda toolkit completes."
		wget http://developer.download.nvidia.com/compute/cuda/4_2/rel/toolkit/cudatoolkit_4.2.9_linux_32_ubuntu11.04.run
		sudo sh cudatoolkit_4.2.9_linux_64_ubuntu11.04.run
		
		wget http://developer.download.nvidia.com/compute/cuda/4_2/rel/sdk/gpucomputingsdk_4.2.9_linux.run
		sudo sh gpucomputingsdk_4.2.9_linux.run
		
	;;
	"4.1-64" | "4.1")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "for versions this old, the sdk is seperate and will install after the cuda toolkit completes."
		wget http://developer.download.nvidia.com/compute/cuda/4_1/rel/toolkit/cudatoolkit_4.1.28_linux_64_ubuntu11.04.run
		sudo sh cudatoolkit_4.1.28_linux_32_ubuntu11.04.run
		
		wget http://developer.download.nvidia.com/compute/cuda/4_1/rel/sdk/gpucomputingsdk_4.1.28_linux.run
		sudo sh gpucomputingsdk_4.1.28_linux.run
	;;
	"4.1-32")
		echo "these downloads do not have 'ubuntu wsl' as an option, and may not work. these are normal ubuntu installers."
		echo "for versions this old, the sdk is seperate and will install after the cuda toolkit completes."
		wget http://developer.download.nvidia.com/compute/cuda/4_1/rel/toolkit/cudatoolkit_4.1.28_linux_32_ubuntu11.04.run
		sudo sh cudatoolkit_4.1.28_linux_32_ubuntu11.04.run
		
		wget http://developer.download.nvidia.com/compute/cuda/4_1/rel/sdk/gpucomputingsdk_4.1.28_linux.run
		sudo sh gpucomputingsdk_4.1.28_linux.run
	;;	
esac

samples=$(echo "$samples" | tr '[:upper:]' '[:lower:]')

if [[ "$samples" == "y" || "$samples" == "yes" ]]; then
	echo "Downloading samples requested..."
	echo "First, downloading/updating 7-zip"
	sudo apt install p7zip-full
	
	if (( $(echo "$major.$minor >= 12.1" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v12.1.zip
		7z x v12.1.zip
		cd cuda-samples-12.1/Samples/1_Utilities/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 12.0" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v12.0.zip
		7z x v12.0.zip
		cd cuda-samples-12.0/Samples/1_Utilities/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.8" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.8.zip
		7z x v11.8.zip
		cd cuda-samples-11.8/Samples/1_Utilities/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.6" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.6.zip
		7z x v11.6.zip
		cd cuda-samples-11.6/Samples/1_Utilities/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.5" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.5.zip
		7z x v11.5.zip
		cd cuda-samples-11.5/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.4" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.4.1.zip
		7z x v11.4.1.zip
		cd cuda-samples-11.6/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.3" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.3.zip
		7z x v11.3.zip
		cd cuda-samples-11.3/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.2" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.2.zip
		7z x v11.2.zip
		cd cuda-samples-11.2/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.1" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.1.zip
		7z x v11.1.zip
		cd cuda-samples-11.1/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 11.0" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v11.0.zip
		7z x v11.0.zip
		cd cuda-samples-11.0/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 10.2" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v10.2.zip
		7z x v10.2.zip
		cd cuda-samples-10.2/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 10.1" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v10.1.zip
		7z x v10.1.zip
		cd cuda-samples-10.1/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 10.0" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v10.0.zip
		7z x v10.0.zip
		cd cuda-samples-10.0/Samples/deviceQuery
		make
		./deviceQuery
	elif (( $(echo "$major.$minor >= 9.2" | bc -l) )); then
		wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v9.2.zip
		7z x v9.2.zip
		cd cuda-samples-9.2/Samples/deviceQuery
		make
		./deviceQuery
	fi
else
	echo "Exiting."
fi
