---
title: "Learning Git"
date: 2019-10-13
draft: false
---
### Git 配置

Git 提供了git config工具, 专门用来配置或读取相应的工作环境变量:

这些环境变量决定了 Git 在各个环节的具体工作方式和行为:

- `/etc/gitconfig` 文件: 系统中对所有用户都普遍适用的配置. 若使用 `git config` 时用 `--system` 选项读写的就是这个文件.

- `~/.gitconfig` 文件:用户目录下的配置文件只适用于该用户. 若使用 `git config` 时用 `--global` 选项读写的就是这个文件.

- `.git/config` 文件: 当前项目的 Git 目录中的配置文件, 仅针对当前项目有效. 

  

#### 用户信息

配置个人的用户名称和电子邮件地址：

```
$ git config --global user.name "runoob"
$ git config --global user.email test@runoob.com
```

如果用了 **--global** 选项, 所有的项目都会默认使用这里配置的用户信息. 如果要在某个特定的项目中使用其他名字或者电邮, 只要去掉 --global 选项重新配置即可

- 使用 git config --list 命令查看当篇配置信息.



### Git 工作流程

工作流程如下:

- 克隆 Git 资源作为工作目录
- 在克隆的资源上添加或修改文件

- 如果其他人修改了, 你可以更新资源
- 在提交前查看修改
- 提交修改
- 在修改完成后, 如果发现错误, 可以撤回提交并再次修改并提交

Git 中有 工作区  暂存区 和 版本库 三个概念:

- **工作区**：就是你在电脑里能看到的目录。
- **暂存区**：英文叫stage, 或index。一般存放在 ".git目录下" 下的index文件（.git/index）中，所以我们把暂存区有时也叫作索引（index）。
- **版本库**：工作区有一个隐藏目录.git，这个不算工作区，而是Git的版本库。

当对工作区修改（或新增）的文件执行 "git add" 命令时，暂存区的目录树被更新，同时工作区修改（或新增）的文件内容被写入到对象库中的一个新的对象中，而该对象的ID被记录在暂存区的文件索引中。

当执行提交操作（git commit）时，暂存区的目录树写到版本库（对象库）中，master 分支会做相应的更新。即 master 指向的目录树就是提交时暂存区的目录树。

当执行 "git reset HEAD" 命令时，暂存区的目录树会被重写，被 master 分支指向的目录树所替换，但是工作区不受影响。

当执行 "git rm --cached <file>" 命令时，会直接从暂存区删除文件，工作区则不做出改变。

当执行 "git checkout ." 或者 "git checkout -- <file>" 命令时，会用暂存区全部或指定的文件替换工作区的文件。这个操作很危险，会清除工作区中未添加到暂存区的改动。

当执行 "git checkout HEAD ." 或者 "git checkout HEAD <file>" 命令时，会用 HEAD 指向的 master 分支中的全部或者部分文件替换暂存区和以及工作区中的文件。这个命令也是极具危险性的，因为不但会清除工作区中未提交的改动，也会清除暂存区中未提交的改动。



### 创建仓库

1. 初始化

使用当前目录作为Git仓库，我们只需使它初始化。

```
git init
```

该命令执行完后会在当前目录生成一个 .git 目录。

使用我们指定目录作为Git仓库。

```
git init newrepo
```

初始化后，会在 newrepo 目录下会出现一个名为 .git 的目录，所有 Git 需要的数据和资源都存放在这个目录中。

如果当前目录下有几个文件想要纳入版本控制，需要先用 git add 命令告诉 Git 开始对这些文件进行跟踪，然后提交：

```
$ git add *.c
$ git add README
$ git commit -m '初始化项目版本'
```

以上命令将目录下以 .c 结尾及 README 文件提交到仓库中。

2. 克隆

我们使用 **git clone** 从现有 Git 仓库中拷贝项目（类似 **svn checkout**）。

克隆仓库的命令格式为：

```
git clone <repo>
```

如果我们需要克隆到指定的目录，可以使用以下命令格式：

```
git clone <repo> <directory>
```



### 基本操作

#### git add

​	git add 命令可将该文件添加到缓存, 我们可以使用 **git add .** 命令来添加当前项目的所有文件.

#### git status 
git status 以查看在你上次提交之后是否有修改,  -s 参数输出精简结果.

#### git diff
git diff 命令显示已写入缓存与已修改但尚未写入缓存的改动的区别

```
> 尚未缓存的改动：git diff
> 查看已缓存的改动： git diff --cached
> 查看已缓存的与未缓存的所有改动：git diff HEAD
> 显示摘要而非整个 diff：git diff --stat
```

#### git commit
git add 将想要快照的内容写入缓存区,  git commit 将缓存区内容添加到仓库中, 使用 -m 选项以在命令行中提供提交注释, 如果你觉得 git add 提交缓存的流程太过繁琐, Git 也允许你用 -a 选项跳过这一步.