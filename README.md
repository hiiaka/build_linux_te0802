# Building Ubuntu/Linux for Trenz TE0802

## Environment

- Vivado 2020.2.2
- The board file for TE0802 (`trenz.biz:te0802_2cg_1e:part0:2.0`) - [Included TRD](https://wiki.trenz-electronic.de/display/PD/TE0802+Test+Board#TE0802TestBoard-Download)

## Build Hardware

```
$ cd hw
$ vivado -mode batch -source ./create_prj.tcl
$ cd ..
```

## Fetch sources

```
$ git clone https://github.com/Xilinx/linux-xlnx.git -b xilinx-v2020.2 --depth 1
$ git clone https://github.com/Xilinx/u-boot-xlnx.git -b xilinx-v2020.2 --depth 1
$ git clone https://github.com/Xilinx/device-tree-xlnx.git -b xilinx-v2020.2 --depth 1
$ git clone https://git.kernel.org/pub/scm/utils/dtc/dtc.git
$ git clone https://github.com/Xilinx/arm-trusted-firmware.git -b xilinx-v2020.2 --depth
```

## Build fsbl

```
$ export CROSS_COMPILE=aarch64-linux-gnu-
$ mkdir fsbl; cd fsbl
$ cp ../hw/te0802_test/te0802_test.sdk/design_1_wrapper.xsa .
$ xsct ../gen_fsbl.tcl
set hwdsgn [hsi::open_hw_design design_1_wrapper.xsa]
hsi::generate_app -hw $hwdsgn -os standalone -proc psu_cortexa53_0 -app zynqmp_fsbl -compile -sw fsbl -dir fsbl
$ cd ..
```

## Build PMU firmware

```
$ export CROSS_COMPILE=aarch64-linux-gnu-
$ mkdir pmc; cd pmc
$ cp ../hw/te0802_test/te0802_test.sdk/design_1_wrapper.xsa .
$ xsct ../gen_pmc.tcl
set hwdsgn [hsi::open_hw_design design_1_wrapper.xsa]
hsi::generate_app -os standalone -hw $hwdsgn -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir pmu
$ cd ..
```

## ARM Trusted firmware

```
$ export CROSS_COMPILE=aarch64-linux-gnu-
$ cd arm-trusted-firmware
$ make PLAT=zynqmp RESET_TO_BL31=1
$ cd ..
```

## Build DTS (Option)
If you want to build your own device tree at this time.

```
$ cd device-tree-xlnx
$ cp ../hw/te0802_test/te0802_test.sdk/design_1_wrapper.xsa .
$ hsi
hsi% open_hw_design design_1_wrapper.xsa
hsi% set_repo_path .
hsi% create_sw_design device-tree -os device_tree -proc psu_cortexa53_0
hsi% generate_target -dir my_dts
hsi% close_hw_design [current_hw_design]
hsi% quit
$ cd my_dts
$ gcc -I my_dts -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o system.dts system-top.dts
$ dtc -I dts -O dtb -o system.dtb system.dts
$ cd ../../
```

## Build U-Boot

```
$ export CROSS_COMPILE=aarch64-linux-gnu-
$ export ARCH=aarch64
$ cd u-boot-xlnx
$ make distclean
$ patch -p1 < ../u-boot-xlnx.patch
$ make xilinx_zynqmp_virt_defconfig
$ export DEVICE_TREE="zynqmp-te0802-02"
$ make -j8
$ cd ..
```

## Build Linux Kernel

```
$ export CROSS_COMPILE=aarch64-linux-gnu-
$ cd linux-xlnx
$ patch -p1 < ../linux-xlnx.patch
$ make ARCH=arm64 xilinx_zynqmp_defconfig
$ make ARCH=arm64 menuconfig
$ make ARCH=arm64 -j8
$ cd ..
```

## Build BOOT.bin

```
$ mkdir boot; cd boot
$ cp ../fsbl/fsbl/executable.elf fsbl.elf
$ cp ../pmc/pmu/executable.elf pmufw.elf
$ cp ../arm-trusted-firmware/build/zynqmp/release/bl31/bl31.elf .
$ cp ../u-boot-xlnx/u-boot.elf .
$ cp ../hw/te0802_test/te0802_test.runs/impl_1/design_1_wrapper.bit test.bit
$ bootgen -image ../boot.bif -arch zynqmp -w -o i BOOT.bin
$ ../u-boot-xlnx/tools/mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "boot.scr" -d ../boot.script boot.scr
$ cd ..
```

## Build userland (Ubuntu)

```
$ sudo apt install debootstrap # if required
$ mkdir -p arm64
$ sudo debootstrap --foreign --arch arm64 bionic ./arm64 http://ports.ubuntu.com/
$ sudo apt install qemu-user-static
$ sudo cp /usr/bin/qemu-aarch64-static ./arm64/usr/bin/
$ sudo chroot ./arm64
I have no name!@qdev:/# ./debootstrap/debootstrap --second-stage
I have no name!@qdev:/# passwd
I have no name!@qdev:/# su
root@ubuntu:# passwd
root@ubuntu:# locale-gen ja_JP.UTF-8 en_US.UTF-8
root@ubuntu:# apt install software-properties-common
root@ubuntu:# add-apt-repository universe && apt update
root@ubuntu:# apt install build-essential flex bison net-tools
root@ubuntu:# apt install openssh-server
root@ubuntu:# systemctl enable ssh
root@ubuntu:# adduser user
root@ubuntu:# apt install git
root@ubuntu:# mkdir -p /usr/local/src/; cd /usr/local/src
root@ubuntu:# git clone -b v1.4.7 https://git.kernel.org/pub/scm/utils/dtc/dtc.git dtc && cd dtc
root@ubuntu:# make && make HOME=/usr install-bin
root@ubuntu:# cd .. && rm -rf dtc
root@ubuntu:# sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
root@ubuntu:# sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
root@ubuntu:# sed -i -e 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
```

## Put all files into MicroSD

- make FAT32(1st) and Ext4(2nd) partitions
- copy the following files int the 1st partition
  - boot/BOOT.bin
  - boot/boot.scr
  - linux-xlnx/arch/arm64/boot/Image
  - linux-xlnx/arch/arm64/boot/dts/xilinx/zynqmp-te0802-02.dtb
- extract user land into the 2nd partition

## PL configuration

Run the following commands on TE0802.

```
$ cat > fpga.dts
/dts-v1/;
/ {
    fragment@0 {
        target-path = "/fpga-full";
        __overlay__ {
            firmware-name = "fpga.bin";
        };
    };
};
Ctrl-D
$ dtc -I dts -O dtb -o fpga.dtb fpga.dts
$ python3 fpga-bit2bin.py -f test.bit test.bin
$ su -
# mkdir -p /lib/firmware
# cp ~user/test.bit /lib/firmware/fpga.bin
# mkdir -p /sys/kernel/config/device-tree/overlays/fpga
# cp ~user/fpga.dtb /sys/kernel/config/device-tree/overlays/fpga/dtbo
```

## Setup X
(cf. https://qiita.com/ikwzm/items/2a0fbfd2938a893e57d4)

Work on the actual environment on TE0802.

Install required package

```
sudo apt install x-window-system-core
sudo apt install twm jwm
sudo apt install libdrm-dev \
                 libudev-dev \
                 libxext-dev \
                 pkg-config \
                 x11proto-core-dev \
                 x11proto-fonts-dev \
                 x11proto-gl-dev \
                 x11proto-xf86dri-dev \
                 xutils-dev \
                 xserver-xorg-dev \
                 quilt \
                 dh-autoreconf
```

Build a X-server driver for Xilinx's ARM SoC

```
mkdir xserver-xorg-video-armsoc-xilinx
cd xserver-xorg-video-armsoc-xilinx
git init
git remote add freedesktop https://anongit.freedesktop.org/git/xorg/driver/xf86-video-armsoc.git
git fetch freedesktop
git merge freedesktop/master
git clone https://github.com/Xilinx/meta-xilinx/
patch -p1 < meta-xilinx/meta-xilinx-bsp/recipes-graphics/xorg-driver/xf86-video-armsoc/0001-src-drmmode_xilinx-Add-the-dumb-gem-support-for-Xili.patch
git add --update
git add src/drmmode_xilinx/
git commit -m "[add] src/drmmode_xilinx"
./autogen.sh
make clean
./configure --prefix=/usr
make
```

Create `/exc/X11/xorg.conf` as the following.

```
Section "Device"
    Identifier  "ZynqMP"
    Driver      "armsoc"
    Option      "DEBUG" "true"
EndSection
Section "Screen"
    Identifier  "DefaultScreen"
    Device      "ZynqMP"
EndSection
```

Create `/root/.xsession` as the following.

```
#!/bin/sh
exec jwm
```

After creating `/root/.xsession`, add x-permission for the file

```
chmod 755 /root/.xsession
```

Login from console, and start X server

```
startx
```

