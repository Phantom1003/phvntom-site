---
title: "GNU InLine Assembly "
date: 2019-12-01
draft: false
---
内联汇编是指在 C/C++ 代码中嵌入的汇编代码, 与单纯的汇编源文件不同, 它被嵌入到 C/C++ 的大环境中. 用内联汇编的主要目的是为了提高效率: 假设有一个比较文本差异的程序 diff, 它花了 99% 的时间在 strcmp 这个函数上, 如果用内联汇编实现的一个高效的 strcmp 比用 C 语言实现的快 1 倍; 另一个目的就是为了实现 C 语言无法实现的部分, 比如 context switch 中需要直接对寄存器内容进行修改.



### 格式

```c
asm volatile ( "statements\n\t"
    		 : output_registers			// 非必需
    		 : input_registers			// 非必需
    		 : clobbered_registers );   // 非必需
```

#### Tips

1. 汇编扩展以 asm (\_\__asm__) 开头表示后面部分为汇编, 可选关键词 volatile (\__\_volatile__) 表示严禁将此处的汇编语句和其他语句进行重组优化, 如果没有添加此关键字，则编译器可能会将某些汇编指令优化掉

2. 每条语句使用单独的 " " 包含, 多条语句间用 ; 或者 \n\t 分隔

3. 内嵌汇编表达式包含的4个部分, 各部分由 : 分隔. 这4个部分都不是必须的，任何一个部分都可以为空, 如果后面的部分不为空, 而前面的部分为空, 则前面的 : 都必须保留, 否则无法说明不为空的部分究竟是第几部分

4. 占位符

   ```c
   `__asm__("cmoveq %1, %2, %[result]" : [result] "=r"(result) : "r"(test), "r"(new), "[result]"(old));`
   ```

   如果总共有n个操作数(包括输入和输出)，那么第一个输出操作数的编号为0，逐项递增，总操作数的数目限制在10个(%0、%1、…、%9)。如果要处理很多输入和输出操作，数字型的占位符很快就会变得混乱。为了使条理清晰，GNU编译器(从版本3.1开始)允许声明替换的名称作为占位符。替换的名称在“输入部分”和“输出部分”中声明。格式如下: `[name] "constraint"(C expression)` 声明name后，使用%[name]的形式替换内嵌汇编代码中相应的数字型占位符。

5. 操作数

   C语言表达式可用作内嵌汇编中的汇编指令的操作数。在汇编指令通过对C语言表达式进行操作来执行有意义的作业的情况下，操作数是扩展格式的内嵌汇编的主要特性。每个操作数都由操作数约束字符串指定，后面跟着用圆括号括起来的C语言表达式，例如: `“constraint”(C expression)`操作数约束的主要功能是确定操作数的寻址方式。

6. 输出部分  `__asm__("movl %%cr0, %0" : "=a"(cr0));`

   圆括号括起来的部分是一个C语言表达式, 用来保存内嵌汇编的输出值, 等于C的赋值 `cr0 = output_value`，因此，圆括号中的输出表达式只能是C的左值表达式。那么右值output_value从何而来呢？

   答案是双引号中的内容，被称作“操作约束”(Operation Constraint)，在这个例子中操作约束为"=a"，它包含两个约束：等号(=)和字母a，其中等号(=)说明圆括号中左值表达式cr0是Write-Only的，只能够被作为当前内嵌汇编的输出，而不能作为输入。而字母a是寄存器EAX/AX/AL的简写，说明cr0的值要从EAX寄存器中获取，也就是说cr0 = %eax，最终这一点被转化成汇编语句就是movl %eax, address_of_cr0。

   另外，需要特别说明的是，很多文档都声明，所有输出操作的操作约束必须包含一个等号(=)，但GCC的文档中却很清楚的声明，并非如此。因为等号(=)约束说明当前的表达式是Write-Only的，但另外还有一个符号——加号(+)用来说明当前表达式是Read-Write的，如果一个操作约束中没有给出这两个符号中的任何一个，则说明当前表达式是Read-Only的。因为对于输出操作来说，肯定是必须是可写的，而等号(=)和加号(+)都表示可写，只不过加号(+) 同时也表示是可读的。所以对于一个输出操作来说，其操作约束只需要有等号(=)或加号(+)中的任意一个就可以了。二者的区别是：等号(=)表示当前操作表达式指定了一个纯粹的输出操作，而加号(+)则表示当前操作表达式不仅仅只是一个输出操作还是一个输入操作。但无论是等号(=)约束还是加号(+)约束所约束的操作表达式都只能放在“输出部分”中，而不能被用在“输入部分”中。在“输出部分”中可以有多个输出操作表达式，多个操作表达式中间必须用逗号(,)分开。

7. 输入部分 `__asm__("movl %0, %%db7" : : "a"(cpu->db7));`

   像输出操作表达式一样，一个输入操作表达式也分为两部分：带圆括号的部分(cpu->db7)和带双引号的部分"a"。这两部分对于一个内嵌汇编输入操作表达式来说也是必不可少的。
   圆括号中的表达式cpu->db7是一个C语言的表达式，它不必是一个左值表达式，也就是说它不仅可以是放在C赋值操作左边的表达式，还可以是放在C赋值操作右边的表达式。所以它可以是一个变量，一个数字，还可以是一个复杂的表达式。

   双引号中的部分是约束部分，和输出操作表达式约束不同的是，它不允许指定加号(+)约束和等号(=)约束，也就是说它只能是默认的Read-Only的。约束中必须指定一个寄存器约束，例中的"a"表示当前输入变量cpu->db7要通过寄存器%eax输入到当前内嵌汇编中。在“输入部分”中可以有多个输入操作表达式，多个操作表达式中间必须用逗号(,)分开。

8. 破坏描述部分

   有时在进行某些操作时，除了要用到进行数据输入和输出的寄存器外，还要使用多个寄存器来保存中间计算结果，这样就难免会破坏原有寄存器的内容。如果希望GCC在编译时能够将这一点考虑进去。那么你就可以在“破坏描述部分”声明这些寄存器或内存。

   这种情况一般发生在一个寄存器出现在“汇编语句模板”，但却不是由输入或输出操作表达式所指定的，也不是在一些输入或输出操作表达式使用"r"、"g"约束时由GCC为其选择的，同时此寄存器被“汇编语句模板”中的指令修改，而这个寄存器只是供当前内嵌汇编临时使用的情况。比如：
   `__asm__("movl %0, %%ebx" : : "a"(foo) : "%ebx");`
   寄存器%ebx出现在“汇编语句模板”中，并且被movl指令修改，但却未被任何输入或输出操作表达式指定，所以你需要在“破坏描述部分”指定"%ebx"，以让GCC知道这一点。

   因为你在输入或输出操作表达式所指定的寄存器，或当你为一些输入或输出操作表达式使用"r"、"g"约束，让GCC为你选择一个寄存器时，GCC对这些寄存器是非常清楚的——它知道这些寄存器是被修改的，你根本不需要在“破坏描述部分”再声明它们。但除此之外，GCC对剩下的寄存器中哪些会被当前的内嵌汇编修改一无所知。所以如果你真的在当前内嵌汇编语句中修改了它们，那么就最好“破坏描述部分”中声明它们，让GCC针对这些寄存器做相应的处理。否则有可能会造成寄存器的不一致，从而造成程序执行错误。

   在“破坏描述部分”中指定这些寄存器的方法很简单，你只需要将寄存器的名字使用双引号引起来。如果有多个寄存器需要声明，你需要在任意两个声明之间用逗号隔开。比如：
   `__asm__("movl %0, %%ebx; popl %%ecx" : : "a"(foo) : "%ebx", "%ecx" );`
   注意准备在“破坏描述部分”声明的寄存器必须使用完整的寄存器名称，在寄存器名称前面使用的“%”是可选的。

   另外需要注意的是，如果你在“破坏描述部分”声明了一个寄存器，那么这个寄存器将不能再被用做当前内嵌汇编语句的输入或输出操作表达式的寄存器约束，如果输入或输出操作表达式的寄存器约束被指定为"r"或"g"，GCC也不会选择已经被声明在“破坏描述部分”中的寄存器。比如：
   `__asm__("movl %0, %%ebx" : : "a"(foo) : "%eax", "%ebx");`
   此例中，由于输出操作表达式"a"(foo)的寄存器约束已经指定了%eax寄存器，那么再在“破坏描述部分”中指定"%eax"就是非法的。编译时，GCC会给出编译错误。

   如果一个内嵌汇编语句的“破坏描述部分”存在"memory"，那么GCC会保证在此内嵌汇编之前，如果某个内存的内容被装入了寄存器，那么在这个内嵌汇编之后，如果需要使用这个内存处的内容，就会直接到这个内存处重新读取，而不是使用被存放在寄存器中的拷贝。因为这个时候寄存器中的拷贝已经很可能和内存处的内容不一致了。

   

9. 操作约束

   在内嵌汇编中的每个操作数都应该由操作数约束字符串描述，后面跟着用圆括号括起来的C语言表达式。操作数约束主要是确定指令中操作数的寻址方式。约束也可以指定：
   ① 是否允许操作数位于寄存器中，以及它可以包括在哪些类型的寄存器中
   ② 操作数是否可以是内存引用，以及在这种情况下使用哪些类型的寻址方式
   ③ 操作数是否可以是立即数

   约束字符必须与指令对操作数的要求相匹配，否则产生的汇编代码将会有错，在这个例子中：
   `__asm__("movl %1,%0" : "=r"(result) : "r"(input));`
   如果将两个"r"，都改为"m"(操作数是内存引用), 很明显这是一条非法指令(mov不允许内存到内存的操作)。

   - r 上面的寄存器的任意一个（谁闲着就用谁）
   - m 内存
   - i 立即数（常量，只用于输入操作数）
   - g 寄存器、内存、立即数 都行（gcc选择）

   ​	

#### Constraint Modifier Characters ( 修 饰 符 )

- ‘=’

  Means that this operand is **written** to by this instruction: the previous value is discarded and replaced by new data.

- ‘+’

  Means that this operand is both **read and written** by the instruction. When the compiler fixes up the operands to satisfy the constraints, it needs to know which operands are read by the instruction and which are written by it. **‘=’ identifies an operand which is only written; ‘+’ identifies an operand that is both read and written;** **all other operands are assumed to only be read. If you specify ‘=’ or ‘+’ in a constraint, you put it in the first character of the constraint string.**

- ‘&’

  Means (in a particular alternative) that this operand is an **early clobber** operand, which is written before the instruction is finished using the input operands. Therefore, this operand may not lie in a register that is read by the instruction or as part of any memory address.‘&’ applies only to the alternative in which it is written. In constraints with multiple alternatives, sometimes one alternative requires ‘&’ while others do not. See, for example, the ‘movdf’ insn of the 68000.A operand which is read by the instruction can be tied to an earlyclobber operand if its only use as an input occurs before the early result is written. Adding alternatives of this form often allows GCC to produce better code when only some of the read operands can be affected by the earlyclobber. See, for example, the ‘mulsi3’ insn of the ARM.Furthermore, if the *earlyclobber* operand is also a read/write operand, then that operand is written only after it’s used.‘&’ does not obviate the need to write ‘=’ or ‘+’. As *earlyclobber* operands are always written, a read-only *earlyclobber* operand is ill-formed and will be rejected by the compiler.

- ‘%’

  Declares the instruction to be commutative for this operand and the following operand. This means that the compiler may interchange the two operands if that is the cheapest way to make all operands fit the constraints. ‘%’ applies to all alternatives and must appear as the first character in the constraint. Only read-only operands can use ‘%’.GCC can only handle one commutative pair in an asm; if you use more, the compiler may fail. Note that you need not use the modifier if the two alternatives are strictly identical; this would only waste time in the reload pass.



#### Simple Constraints ( 约 束 符 )

whitespace

Whitespace characters are ignored and can be inserted at any position except the first. This enables each alternative for different operands to be visually aligned in the machine description even if they have different number of constraints and modifiers.

‘m’

A memory operand is allowed, with any kind of address that the machine supports in general. Note that the letter used for the general memory constraint can be re-defined by a back end using the `TARGET_MEM_CONSTRAINT` macro.

‘o’

A memory operand is allowed, but only if the address is *offsettable*. This means that adding a small integer (actually, the width in bytes of the operand, as determined by its machine mode) may be added to the address and the result is also a valid memory address.

For example, an address which is constant is offsettable; so is an address that is the sum of a register and a constant (as long as a slightly larger constant is also within the range of address-offsets supported by the machine); but an autoincrement or autodecrement address is not offsettable. More complicated indirect/indexed addresses may or may not be offsettable depending on the other addressing modes that the machine supports.

Note that in an output operand which can be matched by another operand, the constraint letter ‘o’ is valid only when accompanied by both ‘<’ (if the target machine has predecrement addressing) and ‘>’ (if the target machine has preincrement addressing).

‘V’

A memory operand that is not offsettable. In other words, anything that would fit the ‘m’ constraint but not the ‘o’ constraint.

‘<’

A memory operand with autodecrement addressing (either predecrement or postdecrement) is allowed. In inline `asm` this constraint is only allowed if the operand is used exactly once in an instruction that can handle the side effects. Not using an operand with ‘<’ in constraint string in the inline `asm` pattern at all or using it in multiple instructions isn’t valid, because the side effects wouldn’t be performed or would be performed more than once. Furthermore, on some targets the operand with ‘<’ in constraint string must be accompanied by special instruction suffixes like `%U0` instruction suffix on PowerPC or `%P0` on IA-64.

‘>’

A memory operand with autoincrement addressing (either preincrement or postincrement) is allowed. In inline `asm` the same restrictions as for ‘<’ apply.

‘r’

A register operand is allowed provided that it is in a general register.

‘i’

An immediate integer operand (one with constant value) is allowed. This includes symbolic constants whose values will be known only at assembly time or later.

‘n’

An immediate integer operand with a known numeric value is allowed. Many systems cannot support assembly-time constants for operands less than a word wide. Constraints for these operands should use ‘n’ rather than ‘i’.

‘I’, ‘J’, ‘K’, … ‘P’

Other letters in the range ‘I’ through ‘P’ may be defined in a machine-dependent fashion to permit immediate integer operands with explicit integer values in specified ranges. For example, on the 68000, ‘I’ is defined to stand for the range of values 1 to 8. This is the range permitted as a shift count in the shift instructions.

‘E’

An immediate floating operand (expression code `const_double`) is allowed, but only if the target floating point format is the same as that of the host machine (on which the compiler is running).

‘F’

An immediate floating operand (expression code `const_double` or `const_vector`) is allowed.

‘G’, ‘H’

‘G’ and ‘H’ may be defined in a machine-dependent fashion to permit immediate floating operands in particular ranges of values.

‘s’

An immediate integer operand whose value is not an explicit integer is allowed.

This might appear strange; if an insn allows a constant operand with a value not known at compile time, it certainly must allow any known value. So why use ‘s’ instead of ‘i’? Sometimes it allows better code to be generated.

For example, on the 68000 in a fullword instruction it is possible to use an immediate operand; but if the immediate value is between -128 and 127, better code results from loading the value into a register and using the register. This is because the load into the register can be done with a ‘moveq’ instruction. We arrange for this to happen by defining the letter ‘K’ to mean “any integer outside the range -128 to 127”, and then specifying ‘Ks’ in the operand constraints.

‘g’

Any register, memory or immediate integer operand is allowed, except for registers that are not general registers.

‘X’

Any operand whatsoever is allowed.

‘0’, ‘1’, ‘2’, … ‘9’

An operand that matches the specified operand number is allowed. If a digit is used together with letters within the same alternative, the digit should come last.

This number is allowed to be more than a single digit. If multiple digits are encountered consecutively, they are interpreted as a single decimal integer. There is scant chance for ambiguity, since to-date it has never been desirable that ‘10’ be interpreted as matching either operand 1 *or* operand 0. Should this be desired, one can use multiple alternatives instead.

```
addl #35,r12
```

Matching constraints are used in these circumstances. More precisely, the two operands that match must include one input-only operand and one output-only operand. Moreover, the digit must be a smaller number than the number of the operand that uses it in the constraint.

‘p’

An operand that is a valid memory address is allowed. This is for “load address” and “push address” instructions.

‘p’ in the constraint must be accompanied by `address_operand` as the predicate in the `match_operand`. This predicate interprets the mode specified in the `match_operand` as the mode of the memory reference for which the address would be valid.

other-letters

Other letters can be defined in machine-dependent fashion to stand for particular classes of registers or other arbitrary operand types. ‘d’, ‘a’ and ‘f’ are defined on the 68000/68020 to stand for data, address and floating point registers.

#### Constraints for Particular Machines

*RISC-V—config/riscv/constraints.md*

f: A floating-point register (if availiable).

I: An I-type 12-bit signed immediate.

J: Integer zero.

K: A 5-bit unsigned immediate for CSR access instructions.

A: An address that is held in a general-purpose register.





### 伪操作

RISC-V工具链基于GCC工具链, 因此, 一般的GNU汇编语法中定义的伪操作均可在RISC-V汇编语言中使用:

- .file filename

  .file伪操作用指示汇编器该汇编程序的逻辑文件名

- .global symbol_name或者.globl symbol_name

  .global和.globl伪操作用于定义一个全局的符号, 使得链接器能够全局识别它, 即一个程序文件中定义的符号能够被所有其他程序文件可见

- .local symbol_name

  .local伪操作用于定义局部符号, 使得此符号不能够被其他程序文件可见

- .weak symbol_name

  1. 在汇编程序中，符号的默认属性为强（strong），.weak伪操作则用于设置符号的属性为弱（weak），如果此符号之前没有定义过，则同时创建此符号并定义其属性为weak。
  2. 如果符号的属性为weak，那么它无需定义具体的内容。在链接的过程中，另外一个属性为strong的同名符号可以将此weak符号的内容强制覆盖。利用此特性，.weak伪操作常用于预先预留一个空符号，使得其能够通过汇编器语法检查，但是在后续的程序中定义符号的真正实体，并且在链接阶段将空符号覆盖并链接。

- .type name , type description

  .type伪操作用于定义符号的类型。譬如“.type symbol,@function”即将名为symbol的符号定义为一个函数（function）。

- .align integer

  .align伪操作用于将当前PC地址推进到“2的integer次方个字节”对齐的位置。譬如“.align 3”即表示将当前PC地址推进到8个字节对齐的位置处。

- .zero integer

  .zero伪操作将从当前PC地址处开始分配integer个字节空间并且用0值填充。譬如“.zero 3”即表示分配三个字节的0值。

- .byte expression [, expression]*

  .byte伪操作将从当前PC地址处开始分配若干个字节（byte）的空间，每个字节填充的值由分号分隔开的expression指定。

- .half expression [, expression]*

  .half伪操作将从当前PC地址处开始分配若干个半字（half-word）的空间，每个半字填充的值由分号分隔开的expression指定。空间分配的地址一定与半字对齐（half-word aligned）。

- .word expression [, expression]*

  .word伪操作将从当前PC地址处开始分配若干个字（word）的空间，每个字填充的值由分号分隔开的expression指定。空间分配的地址一定与字对齐（word aligned）。

- .dword expression [, expression]*

  .dword伪操作将从当前PC地址处开始分配若干个双字（double-word）的空间，每个双字填充的值由分号分隔开的expression指定。空间分配的地址一定与双字对齐（double-word aligned）。

- .string “string”

  .string伪操作将从当前PC地址处开始分配若干个字节空间用于存放“string”字符串。字节的个数取决于字符串的长度。

- .comm或者.common name, length

  .comm和.common伪操作用于声明一个名为name的未初始化存储区间，区间大小为length个字节。由于是未初始化存储区间，在链接阶段会将其链接到.bss段中。

- .option {rvc,norvc,push,pop}

  option伪操作用于设定某些架构特定的选项，使得汇编器能够识别此选项并按照选项的定义采取相应的行为。

  1. rvc、norvc是RISC-V架构特有的选项，用于控制是否生成16位宽的压缩指令:

  ​	“.option rvc”伪操作表示接下来的汇编程序可以被汇编生成16位宽的压缩指令。

  ​	“.option norvc”伪操作表示接下来的汇编程序不可以被汇编生成16位宽的压缩指令。

  2. push、pop用于临时性的保存或者恢复.option伪操作指定的选项：

     “.option push”伪操作暂时将当前的选项设置保存起来，从而允许之后使用.option伪操作指定新的选项；而“.option pop”伪操作将最近保存的选项设置恢复出来重新生效。通过“.option push”和“.option pop”的组合，便可以在汇编程序中在不影响全局选项设置的情况下，为其中嵌入的某一段代码特别地设置不同的选项。

- .section name [, subsection]

  .section伪操作指明将接下来的代码汇编链接到名为name的段（section）当中，还可以指定可选的子段（subsection）。常见的段如.text、.data、.rodata、.bss

- .pushsection name 和.popsection

  .pushsection伪操作将之前的段设置保存起来，并且将当前的段设置改为名为name的段。即，指明将接下来的代码汇编链接到名为name的段中; .popsection伪操作将最近保存的段设置恢复出来。

  通过“.pushsection”和“.popsection”的组合，便可以在汇编程序的编写过程中，在某一个段的汇编代码中特别的插入另外一个段的代码.

- .macro和.endm

  .macro和.emdm伪操作用于将一串汇编代码定义成为一个宏。“.endm”用于结束宏定义。

  “.macro name arg1 [, argn]”用于定义名为name的宏，并且可以传入若干由分号分隔的参数。

- .equ name, value

  .equ伪操作用于将名为name的符号赋值为value的值。