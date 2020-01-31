---
title: "About Spike"
date: 2019-11-08
draft: false
---
Spike is a RISC-V ISA Simulator, which implements a functional model of one or more RISC-V processors. It is named after the golden spike used to celebrate the completion of the US transcontinental railway.

Spike supports the following RISC-V ISA features:

- RV32I and RV64I base ISAs, v2.1
- Zifencei extension, v2.0
- Zicsr extension, v2.0
- M extension, v2.0
- A extension, v2.0
- F extension, v2.2
- D extension, v2.2
- Q extension, v2.2
- C extension, v2.0
- V extension, v0.7.1 (*requires a 64-bit host*)
- Conformance to both RVWMO and RVTSO (Spike is sequentially consistent)
- Machine, Supervisor, and User modes, v1.11
- Debug v0.14



## Build & install RISC-V cross-compiler

Spike is a submodule is [riscv-tools](https://github.com/riscv/riscv-tools), a number of cross-compilation tools are provided in the riscv-tools:

- ~~`riscv-fesvr`: The front-end server that serves system calls on the host machine.~~[Move in riscv-isa-sim]
- ~~`riscv-gnu-toolchain`: The GNU GCC cross-compiler for RISC-V ISA.~~
- `riscv-isa-sim`: The RISC-V ISA simulator (Spike)
- `riscv-pk`: The proxy kernel that serves system calls on target machine.
- `riscv-opcodes`: the enumeration of all RISC-V opcodes executable by the simulator
- `riscv-tests`: a battery of ISA-level tests

To use the spike you need to build the whole RISC-V toolchain, since the submodule repository ***riscv-gnu-toolchain*** has been removed from  the original repository ***riscv-tools***, make sure you have riscvXX-unknown-elf-gcc before the following.

```bash
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev  # for Ubuntu
$ cd $TOP/riscv-tools
$ git submodule update --init --recursive
$ export RISCV=/path/to/install/riscv/toolchain
$ ./build.sh
```

## Compiling and Running a Simple C Program

Install spike (see Build Steps), riscv-gnu-toolchain, and riscv-pk.

Write a short C program and name it hello.c. Then, compile it into a RISC-V ELF binary named hello:

```bash
$ riscv64-unknown-elf-gcc -o hello hello.c
```

Now you can simulate the program atop the proxy kernel:

```bash
$ spike pk hello
```

## Interactive Debug Mode
```bash
$ spike -h             
Spike RISC-V ISA Simulator 1.0.0

usage: spike [host options] <target program> [target options]
Host Options:
  -p<n>                 Simulate <n> processors [default 1]
  -m<n>                 Provide <n> MiB of target memory [default 2048]
  -m<a:m,b:n,...>       Provide memory regions of size m and n bytes
                          at base addresses a and b (with 4 KiB alignment)
  -d                    Interactive debug mode
  -g                    Track histogram of PCs
  -l                    Generate a log of execution
  -h, --help            Print this help message
  -H                    Start halted, allowing a debugger to connect
  --isa=<name>          RISC-V ISA string [default RV64IMAFDC]
  --pc=<address>        Override ELF entry point
  --hartids=<a,b,...>   Explicitly specify hartids, default is 0,1,...
  --ic=<S>:<W>:<B>      Instantiate a cache model with S sets,
  --dc=<S>:<W>:<B>        W ways, and B-byte blocks (with S and
  --l2=<S>:<W>:<B>        B both powers of 2).
  --log-cache-miss      Generate a log of cache miss
  --extension=<name>    Specify RoCC Extension
  --extlib=<name>       Shared library to load
  --rbb-port=<port>     Listen on <port> for remote bitbang connection
  --dump-dts            Print device tree string and exit
  --disable-dtb         Don't write the device tree blob into memory
  --progsize=<words>    Progsize for the debug module [default 2]
  --debug-sba=<bits>    Debug bus master supports up to <bits> wide accesses [default 0]
  --debug-auth          Debug module requires debugger to authenticate
  --dmi-rti=<n>         Number of Run-Test/Idle cycles required for a DMI access [default 0]
  --abstract-rti=<n>    Number of Run-Test/Idle cycles required for an abstract command to execute [default 0]

```
At any point during execution (even without -d), you can enter the interactive debug mode with `-`. To invoke interactive debug mode, launch spike with -d:

```bash
$ spike -d pk hello
```

To see the contents of an integer register (0 is for core 0) or a floating point register:

```bash
: reg 0 a0
: fregs 0 ft0  # single-precision
: fregd 0 ft0  # double-precision
```

To see the contents of a memory location:

```bash
: mem 2020    # physical address in hex
: mem 0 2020  # virtual address (0 for core 0)
```

You can advance by one instruction by pressing . You can also execute until a desired equality is reached:

```bash
: until pc 0 2020                   (stop when pc=2020)
: until mem 2020 50a9907311096993   (stop when mem[2020]=50a9907311096993)
```

Alternatively, you can execute as long as an equality is true:

```bash
: while mem 2020 50a9907311096993
```

You can continue execution indefinitely by:

```bash
: r
```

To end the simulation from the debug prompt, press `-` or:

```bash
: q
```

## Debugging With gdb

An alternative to interactive debug mode is to attach using gdb. Because spike tries to be like real hardware, you also need OpenOCD to do that. OpenOCD doesn't currently know about address translation, so it's not possible to easily debug programs that are run under `pk`. We'll use the following test program:

```bash
$ cat rot13.c 
char text[] = "Vafgehpgvba frgf jnag gb or serr!";

// Don't use the stack, because sp isn't set up.
volatile int wait = 1;

int main()
{
    while (wait)
        ;

    // Doesn't actually go on the stack, because there are lots of GPRs.
    int i = 0;
    while (text[i]) {
        char lower = text[i] | 32;
        if (lower >= 'a' && lower <= 'm')
            text[i] += 13;
        else if (lower > 'm' && lower <= 'z')
            text[i] -= 13;
        i++;
    }

done:
    while (!wait)
        ;
}
$ cat spike.lds 
OUTPUT_ARCH( "riscv" )

SECTIONS
{
  . = 0x10010000;
  .text : { *(.text) }
  .data : { *(.data) }
}
$ riscv64-unknown-elf-gcc -g -Og -o rot13-64.o -c rot13.c
$ riscv64-unknown-elf-gcc -g -Og -T spike.lds -nostartfiles -o rot13-64 rot13-64.o
```

To debug this program, first run spike telling it to listen for OpenOCD:

```bash
$ spike --rbb-port=9824 -m0x10000000:0x20000 rot13-64
Listening for remote bitbang connection on port 9824.
```

In a separate shell run OpenOCD with the appropriate configuration file:

```bash
$ cat spike.cfg 
interface remote_bitbang
remote_bitbang_host localhost
remote_bitbang_port 9824

set _CHIPNAME riscv
jtag newtap $_CHIPNAME cpu -irlen 5 -expected-id 0x10e31913

set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME riscv -chain-position $_TARGETNAME

gdb_report_data_abort enable

init
halt
$ openocd -f spike.cfg
Open On-Chip Debugger 0.10.0-dev-00002-gc3b344d (2017-06-08-12:14)
...
riscv.cpu: target state: halted
```

In yet another shell, start your gdb debug session:

```bash
tnewsome@compy-vm:~/SiFive/spike-test$ riscv64-unknown-elf-gdb rot13-64
GNU gdb (GDB) 8.0.50.20170724-git
Copyright (C) 2017 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "--host=x86_64-pc-linux-gnu --target=riscv64-unknown-elf".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from rot13-64...done.
(gdb) target remote localhost:3333
Remote debugging using localhost:3333
0x0000000010010004 in main () at rot13.c:8
8	    while (wait)
(gdb) print wait
$1 = 1
(gdb) print wait=0
$2 = 0
(gdb) print text
$3 = "Vafgehpgvba frgf jnag gb or serr!"
(gdb) b done 
Breakpoint 1 at 0x10010064: file rot13.c, line 22.
(gdb) c
Continuing.
Disabling abstract command writes to CSRs.

Breakpoint 1, main () at rot13.c:23
23	    while (!wait)
(gdb) print wait
$4 = 0
(gdb) print text
...
```

## Appendix A How to run without pk

Usually programs run in U mode, but programs can be compiled and run in M mode without pk:

Compiling and simulating programs in different modes depends on different tool sets.

- Bare metal mode

  `riscv-gnu-toolchain`(newlib); `riscv-isa-sim`; `riscv-fesvr`.

- User mode

  `riscv-gnu-toolchain`(newlib); `riscv-isa-sim`;  `riscv-pk`;

You can use the file from riscv-test

![bare](/doc-img/spike/bare.png)

hello.c:

```c
#include <stdio.h>
#ifdef BARE_MODE
extern void printstr(const char*);
#endif

int main() {
#ifdef BARE_MODE
  printstr("Hello World!\n");   /* printf is not available in bare-metal mode */
#else
  printf("Hello World!\n");
#endif
}
```

And the makefile like this:

```makefile
default: all

RISCV_PREFIX=riscv64-unknown-elf-
RISCV_GCC = $(RISCV_PREFIX)gcc
RISCV_LINUX_PREFIX=riscv-linux-
RISCV_LINUX_GCC = $(RISCV_LINUX_PREFIX)gcc

RISCV_GCC_OPTS = -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -Os -ffast-math -fno-common 
RISCV_GCC_BARE_LNK_OPTS = -static -nostdlib -nostartfiles -lm -lgcc
RISCV_LINUX_GCC_OPTS = -I.. -O3 -static

hello.bare: hello.bare.o syscalls.o crt.o 
	$(RISCV_GCC) -mcmodel=medany -T ./common/test.ld $^ -o $@ $(RISCV_GCC_BARE_LNK_OPTS)

hello.bare.o:hello.c
	$(RISCV_GCC) -static -DBARE_MODE $(RISCV_GCC_OPTS) -c $< -o $@

syscalls.o:common/syscalls.c
	$(RISCV_GCC) -static -Icommon -Ienv $(RISCV_GCC_OPTS) -c $< -o $@

crt.o:common/crt.S
	$(RISCV_GCC) -static -Icommon -Ienv $(RISCV_GCC_OPTS) -c $< -o $@

hello.pk: hello.c
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $< -o $@

all: hello.bare hello.pk 

clean:
	rm -fr *.o hello.bare hello.linux hello.pk
```

## Appendix B How to add a new instruction / CSR

1. First we need to clone the newest version of opcodes from [here](https://github.com/riscv/riscv-opcodes), then replace the origin old one.

   Add our new instruction in ./opcodes:

   ```
   pac     rd rs1 rs2 31..25=0  14..12=0 6..2=0x1A 1..0=3
   aut     rd rs1 rs2 31..25=1  14..12=0 6..2=0x1A 1..0=3
   ```

   Add our new instruction in ./parse_opcodes:

   ```python
   # Custom Supervisor R/W
   (0x5c0, 'pac_key_l'),
   (0x5c1, 'pac_key_h'),
   ```

   Then we generate the mask code, you may need to explicit declare to use python3 to execute.

   ```bash
   $ cat opcodes-pseudo opcodes opcodes-rvc opcodes-rvc-pseudo opcodes-custom opcodes-rvv opcodes-rvv-pseudo | python3 ./parse_opcodes -c > ./riscv-opc.h
   $ cp ./riscv-opc.h ../../riscv-gnu-toolchain/riscv-binutils/include/riscv-opc.h
   $ make -B install
   ```

2. Add instruction in gcc in /riscv-gnu-toolchain/opcode/riscv-opc.c

   **Notice: Do not insert into a continuous sequence !**

   ```c
   const struct riscv_opcode riscv_opcodes[] = {
   /* name,     xlen, isa,   operands, match, mask, match_func, pinfo.  */
       ......
   {"pac",        0, {"I", 0},   "d,s,t",  MATCH_PAC, MASK_PAC, match_opcode, 0 },
   {"aut",        0, {"I", 0},   "d,s,t",  MATCH_AUT, MASK_AUT, match_opcode, 0 },
       ......
   ```

   **TODO:  Meaning of the parameters**

3. Recompile riscv-gnu-toolchain, and we add new instructions successfully:

![asm](/doc-img/spike/asm.png)

4. Add instruction in Spike

   Create qarma.h/cc in riscv-isa-sim/riscv, pac.h aut.h in */insns.

   Add qarma.h to riscv_hdrs, cc to riscv_srcs, pac aut to riscv_insn_list in riscv.mk.in.

   Add qarma.h to decode.h inorder to use enc/dec function in pac/aut. 

5. Add CSR in Spike

   Add new csr in struct state_t in processor.h

   Write related function set_csr/get_csr in processor.cc

6. Recompiler pk, Spike

![run](/doc-img/spike/run.png)

## Appendix C Why riscv-gnu-toolchian has been removed
When I modified the source code, I found that the encoding.h in /opcodes and /riscv-gnu-toolchain are different, I complained to the RISC-V Foundation about this problem, so you had the following conversation: [Discuss Link](https://github.com/riscv/riscv-binutils-gdb/commit/cfb7ab81ab9c36e83159bad05ea1e3088ea9f816)

FSF (*Free Software Foundation*, I guess...)

![discuss](/doc-img/spike/screenshot.png)
