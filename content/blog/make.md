---
title: "Learning Make"
date: 2019-10-11
draft: false
---

### Makefile 的基本组成:
```make
target ... : prerequisites ...
    command
```
​target是一个目标文件, 可以是Object File, 执行文件, 或者标签; prerequisites是生成target所依赖的文件或目标; command是make需要执行的命令.

### Makefile的工作流程

1. 默认的情况下, make会在当前目录下按顺序找寻文件为**“GNUmakefile” “makefile” “Makefile”**的文件
2. 如果找到, 它会找文件中的第一个目标文件(target), *例如: 会找到edit, 并把这个文件作为最终的目标文件*
3. 如果edit文件不存在, 或是edit所依赖的后面的 .o 文件的文件修改时间要比edit这个文件新, 会执行后面所定义的命令来生成edit这个文件
4. 如果edit所依赖的.o文件不存在, 那么make会在当前文件中找目标为.o文件的依赖性, 如果找到则再根据那一个规则生成.o文件
5. 最终找到.c和.h文件，生成 .o 文件, 用于生成执行文件edit

例子:

```makefile
edit : main.o kbd.o command.o display.o \
	   insert.o search.o files.o utils.o
	cc -o edit main.o kbd.o command.o display.o \  
		  insert.o search.o files.o utils.o  # cc == gcc, cc is used in Unix
main.o : main.c defs.h
	cc -c main.c
kbd.o : kbd.c defs.h command.h
	cc -c kbd.c
command.o : command.c defs.h command.h
	cc -c command.c
display.o : display.c defs.h buffer.h
	cc -c display.c
insert.o : insert.c defs.h buffer.h
	cc -c insert.c
search.o : search.c defs.h buffer.h
	cc -c search.c
files.o : files.c defs.h buffer.h command.h
	cc -c files.c
utils.o : utils.c defs.h
	cc -c utils.c
clean :
	rm edit main.o kbd.o command.o display.o \
	   insert.o search.o files.o utils.o
```

像clean, 没有被第一个目标文件直接或间接关联, 那么它后面所定义的命令将不会被自动执行, 但我们可以通过显示要make执行, 通过使用 make clean, 以此来清除所有的目标文件，以便重编译.

### Makefile 中的变量

   一般在我们书写Makefile时，各部分变量引用的格式我们建议如下：

1. make变量（Makefile中定义的或者是make的环境变量）的引用使用“$(VAR)”格式.
2. 出现在规则命令行中shell变量引用使用shell的“$tmp”格式.

变量类型

1. 递归展开式变量
   第一种风格的变量是递归方式扩展的变量, 通过“=”或者使用指示符“define”定义的. 这种变量在引用的地方是严格遵循文本替换, 此变量值的字符串原模原样的出现在引用它的地方. 变量值中对其他变量的引用不会被替换展开; 而是变量在引用它的地方替换展开的同时, 它所引用的其它变量才会被一同替换展开.

```
foo = $(bar)
bar = $(ugh)
ugh = Huh?         =>      foo = Huh?
```

2. 直接展开式变量
   在使用“:=”定义变量时, 变量值中对其他量或者函数的引用在定义变量时被展开(对变量进行替换). 所以变量被定义后就是一个实际需要的文本串, 其中不再包含任何变量的引用.

```
x := foo
y := $(x) bar
x := later      =>     y = foo bar   x = later
```

3. 延时变量
   “?=”被称为条件赋值: 只有此变量在之前没有赋值的情况下才会对这个变量进行赋值.

### Tips

1. gcc 常用参数

   -c，只编译, 不链接成为可执行文件, 编译器只是由输入的.c等源代码文件生成.o为后缀的目标文件, 通常用于编译不包含主程序的子程序文件

   -o，确定输出文件的名称为output_filename, 同时这个名称不能和源文件同名. 如果不给出这个选项, gcc就给出预设的可执行文件a.out

   -g，产生符号调试工具(GNU的gdb)所必要的符号资讯，要想对源代码进行调试, 我们就必须加入这个选项

   -O，对程序进行优化编译、链接, 采用这个选项，整个源代码会在编译、链接过程中进行优化处理, 这样产生的可执行文件的执行效率可以提高,  编译、链接的速度就相应地要慢一些

   -Idirname，将dirname所指出的目录加入到程序头文件目录列表中, 是在过程中使用的参数

   

2. @通常用在“规则”行的开始处, 表示不显示命令本身，只显示它的结果
   $@  表示目标文件  
   $^  表示所有的依赖文件的完整路径名(目录 + 一般文件名)列表  
   $<  表示第一个依赖文件  
   $?  表示比目标还要新的依赖文件列表  
   $(@D) The directory part of the file name of the target, with the trailing slash removed. If the value of ‘$@’ is dir/foo.o then ‘$(@D)’ is dir. This value is . if ‘$@’ does not contain a slash.$(@F)  
   $(@F) The file-within-directory part of the file name of the target. If the value of ‘$@’ is dir/foo.o then ‘$(@F)’ is foo.o. ‘$(@F)’ is equivalent to ‘$(notdir $@)’.

   

3. $(wildcard *.c) 来获取工作目录下的所有的.c文件列表
   $(eval text) 把text的内容将作为makefile的一部分而被make解析和执行:

```make
OBJ = a.o b.o c.o d.o main.o
define MA
main: $(OBJ)
	gcc  -g -o main $$(OBJ)
endef 
$(eval $(call MA) )
=>
cc -c -o a.o a.c
cc -c -o b.o b.c
cc -c -o c.o c.c
g++ -c -o d.o d.cpp
cc -c -o main.o main.c
gcc -g -o main a.o b.o c.o d.o main.o

# 请注意到$$(OBJ) ,因为make要把这个作为makefile的一行，要让这个地方出现$,就要用两个$,因为两个$,make才把$作为$字符
```

​	 $(foreach var, text, commond) 
​		var：局部变量;  text：文件列表, 空格隔开, 每一次取一个值赋值为变量var ;  commond：对var变量进行操作, 每次操作结果都会以空格隔开, **最后返回空格隔开的列表**.
​	$(subst FROM, TO, TEXT)  将字符串TEXT中的子串FROM变为TO
​	$(word N,TEXT)  取字串“TEXT”中第“N”个单词 **(“N”的值从 1开始)**
​	$(addprefix prefixstr, string1, string2, ...) 给每个string添加前缀

```
$(addprefix chapters/, docx, pdf, jpg)  =>  chapters/docx chapters/pdf chapters/jpg
```

​	$(patsubst \<pattern>, \<replacement>, \<text> )
​	查找\<text>中的单词(单词以空格, Tab, 回车, 换行分隔)是否符合模式\<pattern>, 若匹配, 以\<replacement>替换.
​	 \<pattern>可以包括通配符%, **表示任意长度的字串**.  如果\<replacement>中也包含%, 则\<replacement>中的%将是\<pattern>中的那个“%”所代表的字串. （可以用“\”来转义，以“%”来表示真实含义的“%”字符）

```makefile
src=$(wildcard *.c */*.c */*/*.c)
# 获取了当前目录及子目录下所有的匹配 .c 的文件名(包括路径), 如果目录深度增加的话，加 */ 即可。
dir=$(notdir $(src))
# 去除了或者文件名的路径信息
obj=$(patsubst %.c, %.o, $(src))
# 从第一句匹配到的字符串里将 .c 换成了 .o
```

4. 反斜杠 **\\** 换行符

   通配符 **\*** 代替任意长度字符串, 如果文件名中有通配符, 可以用转义字符\，如 \\* 来表示真实的 * 字符

```makefile
# 在命令中使用通配符
clean:
	rm -f *.o
# 在规则中使用通配符
print: *.c
	lpr -p $?
	touch print
# 在变量中使用通配符
   objects = *.o
# 但变量并不会就[*.o]会展开, 其值就是*.o. Makefile中的变量其实就是C/C++中的宏. 如果需要让通配符在变量中展开, 也就是让objects的值是所有[.o]的文件名的集合: objects := $(wildcard *.o)
```



5. 引用其他的makefile

   使用include关键字可以把别的Makefile包含进来, 被包含的文件会原模原样的放在当前文件的包含位置

```
    include <filename> filename可以是当前操作系统Shell的文件模式（可以保含路径和通配符）
```

**在include前面可以有一些空字符, 但不能是[Tab]键开始. include和filename可以用一个或多个空格隔开. **

例如: 有a.mk, b.mk, c.mk, foo.make, $(bar) = e.mk f.mk, 则 include foo.make *.mk $(bar) 等价于:

​	include foo.make a.mk b.mk c.mk e.mk f.mk



6. 变量值的替换

   - 使用指定字符串替换变量中的后缀字符(串) $(var:a=b)或${var:a=b}     *Tips: a中不能有空格*

   - 变量的模式替换 $(var:a%b=x%y)或${var:a%b=x%y}

     ```
     a123b.c $(a%b.c=x%y) => x123y
     
     ```

   - 规则中的模式替换

     ```
     targets:target-pattern:prereq-pattern
     	command1
         command2
     从targets中匹配子目标, 再通过prereq-pattern从子目标生成依赖, 进而构成完整规则.
     objs := func.o main.o
     $(objs): %.o : %.c
     	gcc -o $@ -c $^
     
     ```

     



