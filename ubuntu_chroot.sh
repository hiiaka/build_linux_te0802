#!/bin/sh

./debootstrap/debootstrap --second-stage
passwd
su # after, exit
locale-gen ja_JP.UTF-8 en_US.UTF-8
apt install -y software-properties-common
add-apt-repository universe && apt update
apt install -y build-essential flex bison net-tools \
               kmod openssh-client openssh-server \
               git cmake \
               dialog perl \
               sudo ifupdown net-tools ethtool udev iputils-ping resolvconf wget apt-utils man devmem2 vim zsh \
               python3 python3-dev python3-pip \
               x-window-system-core \
               twm jwm \
               libdrm-dev \
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
systemctl enable ssh
adduser fpga
mkdir -p /usr/local/src/; cd /usr/local/src
git clone -b v1.4.7 https://git.kernel.org/pub/scm/utils/dtc/dtc.git dtc && cd dtc
make && make HOME=/usr install-bin
cd .. && rm -rf dtc
sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i -e 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

exit 0
