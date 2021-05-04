#!/bin/bash -eu

rm arm-trusted-firmware device-tree-xlnx dtc fsbl linux-xlnx pmc u-boot-xlnx -rf
cd hw
rm te0802_test vivado* -rf
cd ..

