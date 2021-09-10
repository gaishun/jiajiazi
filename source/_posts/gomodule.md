---
title: go module
date: 2021-09-11 00:08:02
tags:
- go
---

拖了这么久，终于还是要来补课。
<!--more-->
### 网络问题

因为网络的问题，先把网络问题给解决掉。

设置

```shell
export GOPROXY=https://goproxy.cn
export GOMODULE=on
```

### 介绍

其实个人感觉跟JAVA里面的maven差不多，一个以来管理工具。

### 初始化

```shell
cd $project_name
go mod init project_name
```

### 检测依赖

```shell
go mod tidy
```

这个命令会检测该文件夹目录下所有引入的依赖，写入`go.mod`文件中，但是此时依赖还没有下载，类似：

```makefile
module google.golang.org/grpc/examples

go 1.14

require (
	github.com/golang/protobuf v1.4.3
	golang.org/x/oauth2 v0.0.0-20200107190931-bf48bf16ab8d
	google.golang.org/genproto v0.0.0-20200806141610-86f49bd18e98
	google.golang.org/grpc v1.36.0
	google.golang.org/protobuf v1.25.0
)

replace google.golang.org/grpc => ../
```



### 下载依赖

```shell
go mod download
```

将依赖全部下载至GOPATH下，会在项目的根目录生成`go.sum`文件，这个文件是依赖的详细依赖。

### 导入依赖

```shell
go mod vendor
```

这里就是将GOPATH下的依赖转移至该项目根目录下的vendor目录下，此时就可以使用这些依赖了。

### 添加依赖

有两种方式可以添加依赖：

- 你只要在项目中有 import，然后 go build 就会 go module 就会自动下载并添加。
- 自己手工使用 go get 下载安装后，会自动写入 go.mod 。

### 常用命令

```shell
go mod init  # 初始化go.mod
go mod tidy  # 更新依赖文件
go mod download  # 下载依赖文件
go mod vendor  # 将依赖转移至本地的vendor文件
go mod edit  # 手动修改依赖文件
go mod graph  # 打印依赖图
go mod verify  # 校验依赖
```


