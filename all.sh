#!/bin/bash -eu

JOBS=$[$(grep cpu.cores /proc/cpuinfo | sort -u | sed 's/[^0-9]//g') + 1]

cd hw
rm -rf te0802_test
vivado -mode batch -source ./create_prj.tcl
cd ..

git clone https://github.com/Xilinx/linux-xlnx.git -b xilinx-v2020.2 --depth 1
git clone https://github.com/Xilinx/u-boot-xlnx.git -b xilinx-v2020.2 --depth 1
git clone https://github.com/Xilinx/device-tree-xlnx.git -b xilinx-v2020.2 --depth 1
git clone https://git.kernel.org/pub/scm/utils/dtc/dtc.git
git clone https://github.com/Xilinx/arm-trusted-firmware.git -b xilinx-v2020.2 --depth 1

export CROSS_COMPILE=aarch64-linux-gnu-
mkdir fsbl; cd fsbl
cp ../hw/te0802_test/te0802_test.sdk/design_1_wrapper.xsa .
xsct ../gen_fsbl.tcl
cd ..

export CROSS_COMPILE=aarch64-linux-gnu-
mkdir pmc; cd pmc
cp ../hw/te0802_test/te0802_test.sdk/design_1_wrapper.xsa .
xsct ../gen_pmc.tcl
cd ..

export CROSS_COMPILE=aarch64-linux-gnu-
cd arm-trusted-firmware
make PLAT=zynqmp RESET_TO_BL31=1
cd ..

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=aarch64
cd u-boot-xlnx
make distclean
patch -p1 < ../u-boot-xlnx.patch
make xilinx_zynqmp_virt_defconfig
export DEVICE_TREE="zynqmp-te0802-02"
make -j${JOBS}
cd ..

export CROSS_COMPILE=aarch64-linux-gnu-
cd linux-xlnx
git checkout -b linux-xlnx-v2020.2-zynqmp-fpga refs/tags/xilinx-v2020.2
patch -p1 < ../linux-xlnx.patch
make ARCH=arm64 xilinx_zynqmp_defconfig
#make ARCH=arm64 menuconfig
make ARCH=arm64 -j${JOBS}
cd ..

mkdir boot; cd boot
cp ../fsbl/fsbl/executable.elf fsbl.elf
cp ../pmc/pmu/executable.elf pmufw.elf
cp ../arm-trusted-firmware/build/zynqmp/release/bl31/bl31.elf .
cp ../u-boot-xlnx/u-boot.elf .
cp ../hw/te0802_test/te0802_test.runs/impl_1/design_1_wrapper.bit test.bit
bootgen -image ../boot.bif -arch zynqmp -w -o i BOOT.bin
../u-boot-xlnx/tools/mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "boot.scr" -d ../boot.script boot.scr
cd ..

mkdir image
cp boot/BOOT.bin image/
cp boot/boot.scr image/
cp linux-xlnx/arch/arm64/boot/Image image/
cp linux-xlnx/arch/arm64/boot/dts/xilinx/zynqmp-te0802-02.dtb image/

