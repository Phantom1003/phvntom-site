---
title: "Xilinx Vc707 [NeedtoFill]"
date: 2020-01-16
draft: false
---
{{< figure src="/doc-img/fpga/vc707.png" alt="vc707" class="img-lg" >}}

## Requirement

```bash
$ git clone https://github.com/sifive/freedom.git
$ cd freedom
$ git submodule update --init --recursive

sudo apt update
sudo apt upgrade
sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev python wget
sudo apt-get install default-jre

# chisel
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
sudo apt-get update
sudo apt-get install sbt
sudo apt install scala

# verilator
sudo apt-get install git make autoconf g++ flex bison
git clone http://git.veripool.org/git/verilator
cd verilator
git checkout -b verilator_3_922 verilator_3_922
unset VERILATOR_ROOT # For bash, unsetenv for csh
autoconf # To create ./configure script
./configure
make -j `nproc`
sudo make install

# other software
$ export RISCV=/path/to/tool-chain/without/'/bin'/in/the/end
$ export PATH=${PATH}:/tools/Xilinx/Vivado/2016.4/bin

# if don't have vivado license
ifconfig -a
# make sure that the network interface name is `eth0`. If not, the Vivado cannot recognize the license from the NIC interface when it is similar to `enp0s25`. 
# rename the network interface:
sudo vim /etc/default/grub
# add in the end: GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo update-grub
reboot
```



## Build

### Config Board

The Makefile corresponding to the Freedom U500 VC707 FPGA Dev Kit is `Makefile.vc707-u500devkit` and it consists of two main targets:

- `verilog`: to compile the Chisel source files and generate the Verilog files.
- `mcs`: to create a Configuration Memory File (.mcs) that can be programmed
  onto an VC707 FPGA board.

```sh
make -f Makefile.vc707-u500devkit verilog
make -f Makefile.vc707-u500devkit mcs
```

If you do not have PCI Express Gen1/2/3 FMC Module run following commands:

```sh
make MODEL=VC707BaseShell -f Makefile.vc707-u500devkit verilog
make MODEL=VC707BaseShell -f Makefile.vc707-u500devkit mcs
```

These will place the files under `builds/vc707-u500devkit/obj`.

Connect **JTAG** line to board, launch **Vivado 2016.4**:

1. Open "Hardware Manager" 
2. Right click on the FPGA device and select “Add Configuration Memory Device" 
3. Config

|    Option    |         Value          |
| :----------: | :--------------------: |
|     Part     | mt28gu01gaax1e-bpi-x16 |
| Manufacturer |         Micron         |
|    Alias     |       28f00ag18f       |
|    Family    |          g18           |
|     Type     |          bpi           |
|   Density    |          1024          |
|    Width     |          x16           |

4. Click OK to “Do you want to program the configuration memory device now ?”
5. Add `freedom-u500-vc707-0-1.mcs` and `freedom-u500-vc707-0-1.prm`
6. Select RS Pins = 25:24, and then OK



### Build boot SD Card

```bash
# In Freedom U SDK
sudo dd if=work/bbl.bin of=/dev/sdb  bs=1M 

# Do not use 
# sudo make DISK=/dev/sdb format-boot-loader 
# cause not support second partition

# Tips: make SD card file system
sudo mkfs.vfat -F 32 /dev/sdb
sudo mkfs.ext4 /dev/sdb 
```



### 3 Boot Log



### About Ethernet

![discuss](/doc-img/fpga/discuss.png)

{{< figure src="/doc-img/fpga/demo.png" alt="sifive demo" class="img-lg" >}}


#### Reference
* https://forums.sifive.com/t/how-to-run-program-in-freedom-u-sdk-linux-on-vc707/2546/7
* https://forums.sifive.com/t/the-network-of-vc707-not-available-after-loading-the-version-without-pcie-card/2930