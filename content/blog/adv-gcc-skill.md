---
title: "Advance GCC Programing Skill [Todo]"
date: 2019-11-02
draft: false
---
### \__attribute__((noinline)) constant variable attribute

```c
__attribute__((noinline)) const int m = 1;
```

The `noinline` variable attribute prevents the compiler from making any use of a constant data value for optimization purposes, without affecting its placement in the object.

You can use this feature for patchable constants, that is, data that is later patched to a different value. It is an error to try to use such constants in a context where a constant value is required. For example, an array dimension.



### \__attribute__((noinline)) function attribute

```c
int fn(void) __attribute__((noinline));
int fn(void) { return 42; }
```

This function attribute suppresses the inlining of a function at the call points of the function. This function attribute is a GNU compiler extension that the ARM compiler supports. It has the `__declspec` equivalent `__declspec(noinline)` In GNU mode, if this attribute is applied to a type instead of a function, the result is a warning rather than an error.

 

###  __declspec(noinline)

```c
/* Prevent y being used for optimization */
__declspec(noinline) const int y = 5;
/* Suppress inlining of foo() wherever foo() is called */
__declspec(noinline) int foo(void);
```

The `__declspec(noinline)` attribute suppresses the inlining of a function at the call points of the function.

`__declspec(noinline)` can also be applied to constant data, to prevent the compiler from using the value for optimization purposes, without affecting its placement in the object. This is a feature that can be used for patchable constants, that is, data that is later patched to a different value. It is an error to try to use such constants in a context where a constant value is required. For example, an array dimension.

#### Note:

This `__declspec` attribute has the function attribute equivalent `__attribute__((noinline))`.



### -finstrument-functions option

```c
void __cyg_profile_func_enter(void * a, void * b) __attribute__((no_instrument_function));
void __cyg_profile_func_exit(void * a, void * b)  __attribute__((no_instrument_function));

void __cyg_profile_func_enter(void * a, void * b) { asm ("ebreak\n\t" :: ); } 
void __cyg_profile_func_exit(void * a, void * b)  { asm ("ebreak\n\t" :: ); }
```

```assembly
000000000001018c <main>:
   1018c:	7139                	addi	sp,sp,-64
   1018e:	fc06                	sd	ra,56(sp)
   10190:	f822                	sd	s0,48(sp)
   10192:	f426                	sd	s1,40(sp)
   10194:	f04a                	sd	s2,32(sp)
   10196:	0080                	addi	s0,sp,64
   10198:	8486                	mv	s1,ra
   1019a:	87a6                	mv	a5,s1
   1019c:	85be                	mv	a1,a5
   1019e:	67c1                	lui	a5,0x10
   101a0:	18c78513          	addi	a0,a5,396 # 1018c <main>
   101a4:	fb9ff0ef          	jal	ra,1015c <__cyg_profile_func_enter>
   101a8:	67f1                	lui	a5,0x1c
   101aa:	fe87b783          	ld	a5,-24(a5) # 1bfe8 <__clzdi2+0xe2>
   101ae:	fcf43c23          	sd	a5,-40(s0)
```