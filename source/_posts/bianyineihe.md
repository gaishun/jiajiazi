---
title: 编译内核
date: 2021-10-02 02:15:17
tags:
- kernel
- centos
---
编译linux源码作为内核
<!--more -->

## 首先检查是否安装了相应的软件包

```shell
$ yum group list
#原始输出如下
Loaded plugins: fastestmirror, langpacks
There is no installed groups file.
Maybe run: yum groups mark convert (see man yum)
Loading mirror speeds from cached hostfile
Available Environment Groups:
   Minimal Install
   Compute Node
   Infrastructure Server
   File and Print Server
   Basic Web Server
   Virtualization Host
   Server with GUI
   GNOME Desktop
   KDE Plasma Workspaces
   Development and Creative Workstation
Available Groups:
   Compatibility Libraries
   Console Internet Tools
   Development Tools
   Graphical Administration Tools
   Legacy UNIX Compatibility
   Scientific Support
   Security Tools
   Smart Card Support
   System Administration Tools
   System Management
Done
$ yum groups  install  "Development and Creative Workstation" "Compatibility Libraries" -y
#这里安装了编译环境的包，并未为了后续编译安装了“Compatibility Libraries”包，需要等蛮久的

```

## 下载源码

可以从官网上下载源码：https://www.kernel.org/

也可以从镜像站下载源码：https://mirrors.edge.kernel.org/pub/linux/kernel/

国内直接从镜像站下载还是比较靠谱的。

这里我下载的是4.9.46版本，因为测试需要用这个版本的内核

```shell
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/linux-4.9.46.tar.gz
```

## 解压并创建符号链接

```shell
tar zxf linux-4.9.46.tar.gz
ln -sv linux-4.9.46 linux
cd linux
```

这里符号链接可以理解成windows里面的快捷方式，创建好符号链接之后进到内核源码目录中

## 创建 .config 文件

这个文件就是选需要加载的内核模块，使用`make menuconfig`就可以可视化的选择内核模块是否需要加载，但是因为是可视化的，所以就需要`ncurses`包的支持，然后先安装`ncurses`包，再执行`make menuconfig`命令就可以了。如果需要清除以前的配置，可以用`make mrproper`命令来清除以前的配置。

```shell
yum install ncurses ncurses-devel -y
make mrproper
make menuconfig
```

以上就可以进入内核配置参数的界面。

在配置的过程中，需要注意的是：

-   [*]：编译到内核文件中去，类似`vmlinuz-**.el7.x86_64`中
-   [M]：编译到模块文件中去，类似`/lib/modules/***.el7.x86_64/`目录中

## make

然后就可以执行make命令进行编译了

```shell
$ make
#出错了，需要安装openssl的包
$ yum install -y openssl.x86_64 openssl-devel.x86_64

$ make clean 
$ make -j16
```

如果编译出错了，可以执行`make clean`命令清楚之前编译出的文件，然后重新执行`make`命令进行编译。

## 执行 `make modules_install`

## 执行`make install`

## reboot然后选择新编译好的linux内核

## 卸载内核

如果要卸载内核：

-   删除`/lib/modules`目录下对应版本的库文件
-   删除`/usr/src/linux`目录下的源码和压缩文件
-   删除`/boot`启动的内核和内核镜像文件
-   删除`grub.conf`配置文件新内核对应的条目




