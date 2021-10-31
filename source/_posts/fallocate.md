---
title: fallocate
date: 2021-10-31 23:13:09
tags:
- kernel
---

为了生成测试文件而学习这个工具。

<!-- more -->

## 说明

fallocate用于操作为文件分配的磁盘空间，以取消分配或预分配。对于支持fallocate系统调用的文件系统，可以通过分配块并将其标记为未初始化（不需要对数据块进行IO）来快速完成预分配。这比用零填充文件要快得多。

fallocate返回的退出状态在成功时为0，在失败时为1。

## Options

>   ```
>   fallocate [-c|-p|-z] [-o offset] -l length [-n] filename
>   fallocate -d [-o offset] [-l length] filename
>   fallocate -x [-o offset] -l length filename
>   ```
>
>   缩写：KiB,MiB...:1024,1024\*1024 ; KB,MB...:1000,1000\*1000

### -l, --length

指定长度

### -o, --offset

指定偏移

### -n, --keep-size

不修改文件的外观长度。

关于文件EOF的解释：

>   This may effectively allocate blocks past EOF, which can be removed with a truncate.

### -i, --insert-range

插入一个洞(hole)，使用`--offset`，`--length`进行指定洞的位置和大小，并且转移(shifting)，也就是推后原来数据的位置。

### -p, --punch-holes

打一个洞(hole)，使用`--offset`，`--length`进行指定洞的位置和大小。

>   Within the specified range, partial filesystem blocks are zeroed, and whole filesystem blocks are removed from the file.

默认不能和 `--zero-range`选项一起使用，但是默认隐含使用`--keep-size`选项。

之后对这个区间的读操作将返回0。

### -c, --collapse-range

使用`--offset`，`--length`进行指定位置和长度，删除该偏移和长度的内容。

操作完成后，将（offset+length）位置数据接到（offset）的位置，删掉原来这段长度的数据，文件的长度也会减少。

该选项不能和`-n，--keep-size`一起使用

### -d, --dig-holes

检测挖洞(`Detect and dig holes`)。

让文件在位置当变得稀疏，但是不会是有额外的磁盘空间，最小的洞的大小取决于文件系统最小的I/O块的大小，不过通常是4096字节。

当使用这个选项的时候，`--keep-size`选项也是被隐含使用的，如果文件范围没有使用`-o`和`-l`进行指定了，然后分析整个文件的空洞。

>   You can think of this option as doing a "cp --sparse" and then renaming the destination file to the original, without the need for extra disk space.

### -z, --zero-range

零空间，使用`--offset`，`--length`进行指定空间的位置和大小。

>    Within the specified range, blocks are preallocated for the regions that span the holes in the file.

分配零空间在这个范围，然后对这个范围的读操作将返回0，但是不同于`-p`，这个不会remove文件的块。

### -x, --posix

允许 POSIX 操作模式。


