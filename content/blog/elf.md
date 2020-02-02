---
title: "Learning ELF"
date: 2019-10-14
draft: false
---

In computing, the **Executable and Linkable Format** (**ELF**, formerly called **Extensible Linking Format**) is a common standard file format for executables, object code, shared libraries, and core dumps. 

Unlike many proprietary executable file formats, ELF is very flexible and extensible, and it is not bound to any particular processor or Instruction set architecture|architecture. This has allowed it to be adopted by many different operating systems on many different platforms.

### ELF file layout

Each ELF file is made up of one **ELF header**, followed by file data. The file data can include:

- **Program header table**, describing zero or more **segments**
- **Section header table**, describing zero or more **sections**
- Data referred to by entries in the program header table, or the section header table

The **segments** contain information that is necessary for **runtime execution of the file**, while **sections** contain important data for **linking and relocation**. Each byte in the entire file is taken by **no more than one section at a time**, but there can be orphan bytes, which are not covered by a section. In the normal case of a Unix executable **one or more sections are enclosed in one segment**.

{{< figure src="/doc-img/elf/layout.png" alt="layout" class="img-md">}}

### ELF Header

文件开始处是一个 ELF 头部(ELF Header), 用来描述整个文件的组织, 除了 ELF 头部表以外, 其他节区和段都没有规定的顺序.

```bash
readelf -h vmlinux
```

```c
typedef struct elfhdr {
    unsigned char    e_ident[EI_NIDENT]; /* ELF Identification */
    Elf32_Half    e_type;        /* object file type */
    Elf32_Half    e_machine;    /* machine */
    Elf32_Word    e_version;    /* object file version */
    Elf32_Addr    e_entry;    /* virtual entry point */
    Elf32_Off    e_phoff;    /* program header table offset */
    Elf32_Off    e_shoff;    /* section header table offset */
    Elf32_Word    e_flags;    /* processor-specific flags */
    Elf32_Half    e_ehsize;    /* ELF header size */
    Elf32_Half    e_phentsize;    /* program header entry size */
    Elf32_Half    e_phnum;    /* number of program header entries */
    Elf32_Half    e_shentsize;    /* section header entry size */
    Elf32_Half    e_shnum;    /* number of section header entries */
    Elf32_Half    e_shstrndx;    /* section header table's "section 
                       header string table" entry offset */
} Elf32_Ehdr;

typedef struct {
    unsigned char    e_ident[EI_NIDENT];    /* Id bytes */
    Elf64_Quarter    e_type;            /* file type */
    Elf64_Quarter    e_machine;        /* machine type */
    Elf64_Half    e_version;        /* version number */
    Elf64_Addr    e_entry;        /* entry point */
    Elf64_Off    e_phoff;        /* Program hdr offset */
    Elf64_Off    e_shoff;        /* Section hdr offset */
    Elf64_Half    e_flags;        /* Processor flags */
    Elf64_Quarter    e_ehsize;        /* sizeof ehdr */
    Elf64_Quarter    e_phentsize;        /* Program header entry size */
    Elf64_Quarter    e_phnum;        /* Number of program headers */
    Elf64_Quarter    e_shentsize;        /* Section header entry size */
    Elf64_Quarter    e_shnum;        /* Number of section headers */
    Elf64_Quarter    e_shstrndx;        /* String table index */
} Elf64_Ehdr;
```

{{< figure src="/doc-img/elf/header.png" alt="elf-header" class="img-lg">}}

>Magic number of ELF: 7f 45 4c 46  
>Class: 02 -> ELF64  
>Data: 01 -> 2's complement; little endian  
>**Entry point address: [e_entry]** 0x8000 0000  
>**Start of program headers, Size of program headers, Number of program headers:   
>   [e_phoff, e_phentsize, e_phnum]**
>**Start of section headers, Size of section headers, Number of section headers:   
>	[e_shoff, e_shentsize, e_shnum]**
>**Section header string table index: [e_shstrndx]** Index of string table in section table 


### Program Header Table

可执行文件或者共享目标文件的程序头部是一个结构数组, 每个结构描述了一个段或者系统准备程序执行所必需的其它信息. 目标文件的“段”包含一个或者多个“节区”, 也就是“段内容(Segment Contents)”.
**程序头部仅对于可执行文件和共享目标文件有意义**

```bash
readelf -l vmlinux
```

```c
/* Program Header */
typedef struct {
    Elf32_Word    p_type;        /* segment type */
    Elf32_Off    p_offset;    /* segment offset */
    Elf32_Addr    p_vaddr;    /* virtual address of segment */
    Elf32_Addr    p_paddr;    /* physical address - ignored? */
    Elf32_Word    p_filesz;    /* number of bytes in file for seg. */
    Elf32_Word    p_memsz;    /* number of bytes in mem. for seg. */
    Elf32_Word    p_flags;    /* flags */
    Elf32_Word    p_align;    /* memory alignment */
} Elf32_Phdr;

typedef struct {
    Elf64_Half    p_type;        /* entry type */
    Elf64_Half    p_flags;    /* flags */
    Elf64_Off    p_offset;    /* offset */
    Elf64_Addr    p_vaddr;    /* virtual address */
    Elf64_Addr    p_paddr;    /* physical address */
    Elf64_Xword    p_filesz;    /* file size */
    Elf64_Xword    p_memsz;    /* memory size */
    Elf64_Xword    p_align;    /* memory & file alignment */
} Elf64_Phdr;
```
{{< figure src="/doc-img/elf/pheader.png" alt="program-header" class="img-lg">}}

> - p_type 此数组元素描述的段的类型，或者如何解释此数组元素的信息。具体如下图。
> - p_offset 此成员给出从文件头到该段第一个字节的偏移。
> - p_vaddr 此成员给出段的第一个字节将被放到内存中的虚拟地址。
> - p_paddr 此成员仅用于与物理地址相关的系统中。因为 System V 忽略所有应用程序的物理地址信息，此字段对与可执行文件和共享目标文件而言具体内容是指定的。
> - p_filesz 此成员给出段在文件映像中所占的字节数。可以为 0。
> - p_memsz 此成员给出段在内存映像中占用的字节数。可以为 0。
> - p_flags 此成员给出与段相关的标志。
> - p_align 可加载的进程段的 p_vaddr 和 p_offset 取值必须合适，相对于对页面大小的取模而言。此成员给出段在文件中和内存中如何 对齐。数值 0 和 1 表示不需要对齐。否则 p_align 应该是个正整数，并且是 2 的幂次数，p_vaddr 和 p_offset 对 p_align 取模后应该相等。


### Section Header Table

节区中包含目标文件中除了ELF 头部, 程序/节区头部表格外的所有信息, 满足以下条件:

1. 目标文件中的每个节区都有对应的节区头部描述它, 但有节区头部不意味着有节区;
2. 每个节区占用文件中一个连续字节区域(这个区域可能长度为 0);
3. 文件中的节区不能重叠, 不允许一个字节存在于两个节区中;
4. 目标文件中可能包含非活动空间(INACTIVE SPACE), 这些区域不属于任何头部和节区.

```bash
readelf -S vmlinux
```

```c
/* Section Header */
typedef struct {
    Elf32_Word    sh_name;    /* name - index into section header string table section */
    Elf32_Word    sh_type;    /* type */
    Elf32_Word    sh_flags;    /* flags */
    Elf32_Addr    sh_addr;    /* address */
    Elf32_Off    sh_offset;    /* file offset */
    Elf32_Word    sh_size;    /* section size */
    Elf32_Word    sh_link;    /* section header table index link */
    Elf32_Word    sh_info;    /* extra information */
    Elf32_Word    sh_addralign;    /* address alignment */
    Elf32_Word    sh_entsize;    /* section entry size */
} Elf32_Shdr;

typedef struct {
    Elf64_Half    sh_name;    /* section name */
    Elf64_Half    sh_type;    /* section type */
    Elf64_Xword    sh_flags;    /* section flags */
    Elf64_Addr    sh_addr;    /* virtual address */
    Elf64_Off    sh_offset;    /* file offset */
    Elf64_Xword    sh_size;    /* section size */
    Elf64_Half    sh_link;    /* link to another */
    Elf64_Half    sh_info;    /* misc info */
    Elf64_Xword    sh_addralign;    /* memory alignment */
    Elf64_Xword    sh_entsize;    /* table entry size */
} Elf64_Shdr;
```
{{< figure src="/doc-img/elf/sheader.png" alt="section-header" class="img-lg">}}

> * sh_name: 给出节区的名称, 是字符串表节区的索引;
>
> * sh_type: 为节区的内容和语义进行分类;
>
>   * SHT_NULL: 非活动
>
>   * SHT_PROGBITS: 包含程序定义的信息
>
>   * SHT_NOBITS: 此部分不占用程序空间
>
>   * SHT_SYMTAB: 符号表
>
>   * SHT_STRTAB: 字符串表
>
>     ......
>
> * sh_flags: 定义节区中内容是否可以修改, 执行等信息
>
>   * SHF_WRITE: 节区包含进程执行过程中将可写的数据;
>   * SHF_ALLOC: 此节区在进程执行过程中占用内存;
>   * SHF_EXECINSTR: 节区包含可执行的机器指令;
>
> * sh_link & sh_info 



#### 特殊节区

- 以“.”开头的节区名称是系统保留的, 应用程序可以使用没有前缀的节区名称, 以避 免与系统节区冲突。
- 目标文件格式允许人们定义非保留的节区
- 目标文件中也可以包含多个名字相同的节区
- 保留给处理器体系结构的节区名称一般构成为:处理器体系结构名称简写 + 节区
  名称

![常见特殊节区](/doc-img/elf/com-section.png)

#### Reference
[ELF文件格式分析](https://segmentfault.com/a/1190000007103522)








