---
title: "Linker Relaxation"
date: 2019-10-22
draft: false
---


## Registers

Assembler mnemonics for RISC-V integer and floating-point registers.

| Register | ABI Name | Description                       | Caller/Callee |
| :------- | :------- | :-------------------------------- | ------------- |
| x0       | zero     | Hard-wired zero                   |               |
| x1       | ra       | Return address                    | Caller        |
| x2       | sp       | Stack pointer                     | Callee        |
| x3       | gp       | Global pointer                    |               |
| x4       | tp       | Thread pointer                    |               |
| x5       | t0       | Temporary/alternate link register | Caller        |
| x6–x7    | t1-t2    | Temporaries                       | Caller        |
| x8       | s0/fp    | Saved register/frame pointer      | Callee        |
| x9       | s1       | Saved register                    | Callee        |
| x10–x11  | a0-a1    | Function arguments/return values  | Caller        |
| x12–x17  | a2-a7    | Function arguments                | Caller        |
| x18–x27  | s2-s11   | Saved registers                   | Callee        |
| x28–x31  | t3-t6    | Temporaries                       | Caller        |
|          |          |                                   |               |
| f0–f7    | ft0-ft7  | FP temporaries                    | Caller        |
| f8–f9    | fs0-fs1  | FP saved registers                | Callee        |
| f10–f11  | fa0-fa1  | FP arguments/return values        | Caller        |
| f12–f17  | fa2-fa7  | FP arguments                      | Caller        |
| f18–f27  | fs2-fs11 | FP saved registers                | Callee        |
| f28–f31  | ft8-ft11 | FP temporaries                    | Caller        |



**Tips**: ***how to print the preprocessor macros ?***

```bash
$ riscv64-unknown-elf-gcc -march=rv64imac -mabi=lp64 -E -dM - < /dev/null | egrep -i 'risc|fp[^-]|version|abi|lp' | sort  # show the preprocessor macros
```
![preprocessor macros](/doc-img/link-relax/gcc-macro.png)



## Linker Relaxation

**Linker relaxation** is a concept that it has greatly shaped the design of the RISC-V ISA. **Linker relaxation** is a mechanism for optimizing programs at link-time, as opposed to traditional program optimization which happens at compile-time.

In order to understand relaxation, we first must examine the RISC-V ISA a bit. In the RISC-V ISA there are two unconditional control transfer instructions: `jalr`, which **jumps to an absolute address as specified by an immediate offset from a register**; and `jal`, which **jumps to a pc-relative offset as specified by an immediate**. The only differences between the `auipc`+`jalr` pair and a single `jal` are that the pair can address a 32-bit signed offset from the current PC while the `jal` can only address a 21-bit signed offset from the current PC, and that the `jal` instruction is half the size (which is a good proxy for twice the speed).

{{< figure src="/doc-img/link-relax/opcode.png" alt="opcode" class="img-lg">}}


```bash
$ cat test.c 
int func(int a) __attribute__((noinline)); 
int func(int a) { return a + 1; } 
int _start(int a) { return func(a); }
```

As the compiler cannot know if the offset between `_start` and `func` will fit within a 21-bit offset, it is forced to generate the longer call. We don't want to impose this cost in cases where it's not necessary, so we instead optimize this case in the linker. Let's look at the executable to see the result of linker relaxation:

```bash
$ riscv64-unknown-linux-gnu-objdump -d -r test
test:     file format elf64-littleriscv

Disassembly of section .text:

0000000000010078 <func>:
   10078:       2505                    addiw   a0,a0,1
   1007a:       8082                    ret

000000000001007c <_start>:
   1007c:       ffdff06f                j       10078 <func>
```

As you can see, the linker knows that the call from `_start` to `func` fits within the 21-bit offset of the `jal` instruction and converts it to a single instruction.

### Relaxing Against the Global Pointer

It may seem like linker relaxation involves a huge amount of complexity for a small gain: we trade knowing no `.text` section symbol addresses until link time for shortening a few sequences by a single instruction. 

Let's take a look at the Dhrystone source code first, the code performs three accesses to global variables in order to do a simple comparison and a logical operation.

```c
/* Global Variables: */
bool            Bool_Glob;
char            Ch_1_Glob, Ch_2_Glob;

Proc_4 () /* without parameters */
{
  bool Bool_Loc;
  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
} /* Proc_4 */
```

In order to understand the specific relaxation that's being performed in this case, it's probably best to start with the code the toolchain generates before this optimization, which I've copied below:

```assembly
0000000040400826 <Proc_4>:
    40400826:   3fc00797                auipc   a5,0x3fc00
    4040082a:   f777c783                lbu     a5,-137(a5) # 8000079d <Ch_1_Glob>
    4040082e:   3fc00717                auipc   a4,0x3fc00
    40400832:   f7272703                lw      a4,-142(a4) # 800007a0 <Bool_Glob>
    40400836:   fbf78793                addi    a5,a5,-65
    4040083a:   0017b793                seqz    a5,a5
    4040083e:   8fd9                    or      a5,a5,a4
    40400840:   3fc00717                auipc   a4,0x3fc00
    40400844:   f6f72023                sw      a5,-160(a4) # 800007a0 <Bool_Glob>
    40400848:   3fc00797                auipc   a5,0x3fc00
    4040084c:   04200713                li      a4,66
    40400850:   f4e78a23                sb      a4,-172(a5) # 8000079c <Ch_2_Glob>
    40400854:   8082                    ret
```

As you can see, this function consists of 13 instructions, 4 of which are `auipc` instructions. All of these `auipc` instructions are used to calculate the addresses of global variables for a subsequent memory access, and all of these generated addresses are within a 12-bit offset of each other. If you're thinking "we only really need one of these `auipc` instructions", you're both right and wrong: while we could generate a single `auipc` (though that requires some GCC work we haven't done yet and is thus the subject of a future blog post), we can actually do one better and get by with *zero* `auipc` instructions!

If you've just gone and pored over the RISC-V ISA manual to find an instruction that loads `Ch_1_Glob` (which lives at `0x8000079D`) in a single instruction then you should give up now, as there isn't one. There is, of course, a trick -- it is common on register-rich, addressing-mode-poor ISAs to have a dedicated ABI register known as the global pointer that contains an address in the `.data` segment. **The `gp` (Global Pointer) register is a solution to further optimise memory accesses within a single 4KB region(12-bit signed offset).** 

In order to get a bit more visibility into how this works, let's take a look at a snippet of GCC's default linker script for RISC-V:

```assembly
/* We want the small data sections together, so single-instruction offsets
   can access them all, and initialized data all before uninitialized, so
   we can shorten the on-disk segment size.  */
.sdata          :
{
  __global_pointer$ = . + 0x800;   // 0x800 = 4K(0x100) / 2
  *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
  *(.sdata .sdata.* .gnu.linkonce.s.*)
}
_edata = .; PROVIDE (edata = .);
. = .;
__bss_start = .;
.sbss           :
{
  *(.dynsbss)
  *(.sbss .sbss.* .gnu.linkonce.sb.*)
  *(.scommon)
```

As you can see, the magic `__global_pointer$` symbol is defined to point `0x800` bytes past the start of the `.sdata` section. The `0x800` magic number allows signed 12-bit offsets from `__global_pointer$` to address symbols at the start of the `.sdata` section. The linker assumes that if this symbol is defined, then the `gp` register contains that value, which it can then use to relax accesses to global symbols within that 12-bit range. 

The compiler treats the `gp` register as a constant so it doesn't need to be saved or restored, which means it is generally only written by `_start`, the ELF entry point. Here's an example from the RISC-V newlib port's `crt0.S` file:

```assembly
.option push
.option norelax
# RV32
1:auipc gp, %pcrel_hi(__global_pointer$)
  addi  gp, gp, %pcrel_lo(1b)
# RV64
1: la gp, __global_pointer$
.option pop
```

**Note that we need to disable relaxations while setting `gp`, otherwise the linker would relax this two-instruction sequence to `mv gp, gp`**

The linker uses the `__global_pointer$` symbol definition to compare the memory addresses and, if within range, it replaces absolute/pc-relative addressing with gp-relative addressing, which makes the code more efficient. **This process is also called *relaxing*, and can be disabled by `-Wl,--no-relax`.**

The `gp` register should be loaded during startup with the address of the `__global_pointer$` symbol and should not be changed later.

```assembly
00000000400003f0 <Proc_4>:
    400003f0:   8651c783                lbu     a5,-1947(gp) # 80001fbd <Ch_1_Glob>
    400003f4:   8681a703                lw      a4,-1944(gp) # 80001fc0 <Bool_Glob>
    400003f8:   fbf78793                addi    a5,a5,-65
    400003fc:   0017b793                seqz    a5,a5
    40000400:   00e7e7b3                or      a5,a5,a4
    40000404:   86f1a423                sw      a5,-1944(gp) # 80001fc0 <Bool_Glob>
    40000408:   04200713                li      a4,66
    4000040c:   86e18223                sb      a4,-1948(gp) # 80001fbc <Ch_2_Glob>
    40000410:   00008067                ret
```



### Reference
* https://www.sifive.com/blog/all-aboard-part-3-linker-relaxation-in-riscv-toolchain
* http://www.rowleydownload.co.uk/arm/documentation/gnu/as/RISC_002dV_002dDirectives.html