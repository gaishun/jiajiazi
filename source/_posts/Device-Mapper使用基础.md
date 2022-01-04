---
title: Device Mapper使用基础
date: 2021-12-09 20:57:16
tags:
- Device Mapper
---

>   Device Mapper 是Linux内核用来将块设备映射到虚拟块设备的framework，现在的一个想法，就是先找到文件在硬盘上的位置，然后用Device Mapper（以后简称dm）映射成一个块设备，之后的读写就可以直接对这个虚拟块设备进行读写，而不用通过文件系统等等的操作。
>
>   文章参考：https://www.lijiaocn.com/%E6%8A%80%E5%B7%A7/2017/07/07/linux-tool-devicemapper.html
<!-- more -->
## 先放一张非常牛逼的图来镇楼。

![IO_stack_of_the_Linux_kernel](C:\Users\gaishun\Downloads\IO_stack_of_the_Linux_kernel.svg)

使用`lvm`命令管理逻辑卷的时候，最终是通过dm完成的。

`dmsetup`命令可以直接管理dm。

## 虚拟块table

通过`dmsetup table`可以查看虚拟块设备的记录情况，然后格式如下：

```text
logical_start_sector	num_sectors	target_type	target_args
分别代表：
开始扇区				 扇区数		设备类型	设备参数
```

其中设备类型可以去kernel的`documents/device-mapper`里面去找，大致如下：

```text
linear destination_device start_sector
    The traditional linear mapping.
striped num_stripes chunk_size [destination start_sector]...
    Creates a striped area.
    e.g. striped 2 32 /dev/hda1 0 /dev/hdb1 0 will map the first chunk (16k) as follows:
    LV chunk 1 -> hda1, chunk 1
    LV chunk 2 -> hdb1, chunk 1
    LV chunk 3 -> hda1, chunk 2
    LV chunk 4 -> hdb1, chunk 2
error     Errors any I/O that goes to this area.  Useful for testing or for creating devices with holes in them.
zero      Returns blocks of zeroes on reads.  Any data written is discarded silently.  
          This is a block-device equivalent of the /dev/zero character-device data sink described in null(4).
cache     Improves performance of a block device (eg, a spindle) by dynamically migrating some of its data to a faster smaller device (eg, an SSD).
crypt     Transparent encryption of block devices using the kernel crypto API.
delay     Delays reads and/or writes to different devices.  Useful for testing.
flakey    Creates a similar mapping to the linear target but exhibits unreliable behaviour periodically.  
          Useful for simulating failing devices when testing.
mirror    Mirrors data across two or more devices.
multipath
Mediates  access through multiple paths to the same device.
raid      Offers an interface to the kernel's software raid driver, md.
snapshot  Supports  snapshots of devices.
thin, thin-pool
    Supports thin provisioning of devices and also provides a better snapshot support.
```

## 创建虚拟块设备

使用的是`dmsetup create`命令进行创建设备。

```shell
create <dev_name>
          [-j|--major <major> -m|--minor <minor>]
          [-U|--uid <uid>] [-G|--gid <gid>] [-M|--mode <octal_mode>]
          [-u|uuid <uuid>] [--addnodeonresume|--addnodeoncreate]
          [--readahead {[+]<sectors>|auto|none}]
          [-n|--notable|--table {<table>|<table_file>}]
```

-table参数是关键的配置参数，指定了块设备的类型，并根据类型传递了不同的参数。

## thin, thin-pool

thin-provisioning 是dm提供的一种存储类型。

可以将多个虚拟设备存放在同一个数据卷上，减缓了管理，并通过共享数据减少了存储开销。

而且支持快照和递归快照。

kernel文件`Documentation/device-mapper/thin-provisioning.txt`文件中又相继介绍，它将元数据和数据分开，元数据设备的推荐容量是

```
48 * $data_dev_size / $data_block_size, rount up to 2MB
```

### 创建一个thin-pool

thin就是在thin-pool中创建的虚拟设备。

首先需要准备一个metadata设备，可以用一个文件代替：

```shell
dd if=/dev/zero of=metadata bs=512 count=100000	#zero设备提供无限的空字符
losetup /dev/loop0 ./metadata					#将metadata文件虚拟成块设备可以挂载
```

然后就得到了metadata的虚拟块设备，之后可以创建pool

```shell
dmsetup create pool --table "0 1000000 thin-pool /dev/loop0 /dev/loop1 512 1000"
#参数含义如下：
	dmsetup create pool \
	--table "0 20971520 thin-pool $metadata_dev $data_dev \
	 $data_block_size $low_water_mark"

#pool:              自定义的名字
#0:                 开始扇区
#20971520:          结束扇区
#thin-pool:         设备类型
#$metadata_dev:     存放元数据的设备
#$data_dev:         存放数据的设备
#$data_block_size:  数据块大小
#$low_water_mark:   空闲的数据块少于该数值时，发送通知
```

然后使用`dmsetup ls`或者`dmsetup table`就可以查看到该设备。

### 创建thin

```shell
dmsetup message /dev/mapper/pool 0 "create_thin 0"
```

其中，0 是为thin创建的标记号（identifier），不能重复，用户管理。

激活：

```shell
dmsetup create thin --table "0 1000 thin /dev/mapper/pool 0"
```

thin是自定义的名字，可以查看。

```shell
$dmsetup ls
thin	(253:4)

$ls /dev/mapper/thin
/dev/mapper/thin

$ls -lh thin
lrwxrwxrwx. 1 root root 7 Jul 10 05:22 thin -> ../dm-4
```

### 删除thin

```shell
dmsetup message /dev/mapper/pool 0 "delete 0"
dmsetup remove thin
```





## dm-linear

>   ```
>   Device-Mapper's "linear" target maps a linear range of the Device-Mapper
>   device onto a linear range of another device.  
>   This is the basic building block of logical volume managers.
>   ```
>
>   dm-linear就是将一个先行区间的dm设备映射到另一个先行区间的设备，基于逻辑卷的管理进行的？

kernel文档也没写多少，直接写代码吧

### 创建一个设备：

```shell
#!/bin/sh
# Create an identity mapping for a device
echo "0 `blockdev --getsz $1` linear $1 0" | dmsetup create identity
#这里是创建了一个设备，blockdev --getsz 是获取命令行参数提供的设备的大小。
# “0，size, linear, device, 0”分别对应
# logical_start_sector
# number_sectors
# target_type        #type之后的参数数据target_type_args不同type不同参数
# destination_device
# start_sector
# identify           #创建的目标设备，目标设备会在/dev/mapper/中
```

### 两个设备合并成一个设备

```shell
#!/bin/sh
# Join 2 devices together
size1=`blockdev --getsz $1`
size2=`blockdev --getsz $2`
#下面echo其实就是一个table，
#本行起始逻辑地址|本行逻辑长度|linear|设备|这块长度对应到设备上的起始地址
#多行做成一个表格，送给dmsetup create dm_device_name "table"
echo "0 $size1 linear $1 0
$size1 $size2 linear $2 0" | dmsetup create joined
```

### 将一个设备分成固定大小的块，然后反向组合

```shell
#!/usr/bin/perl -w
# Split a device into 4M chunks and then join them together in reverse order.

my $name = "reverse";
my $extent_size = 4 * 1024 * 2;
my $dev = $ARGV[0];
my $table = "";
my $count = 0;

if (!defined($dev)) {
        die("Please specify a device.\n");
}

my $dev_size = `blockdev --getsz $dev`;
my $extents = int($dev_size / $extent_size) -
              (($dev_size % $extent_size) ? 1 : 0);

while ($extents > 0) {
        my $this_start = $count * $extent_size;
        $extents--;
        $count++;
        my $this_offset = $extents * $extent_size;

        $table .= "$this_start $extent_size linear $dev $this_offset\n";
}

`echo \"$table\" | dmsetup create $name`;
```






