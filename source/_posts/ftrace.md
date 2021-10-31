---
title: ftrace
date: 2021-10-27 15:57:33
tags:
- [内核,ftrace]

---
因为，需要明白内核函数之间的调用关系，所以学习该工具。

<!-- more -->

## 干什么用

ftrace 是一个 Linux 内部的 trace 工具，能够帮助开发者和系统设计者知道内核当前正在干啥，从而更好的去分析性能问题。

Ftrace 能帮我们分析内核特定的事件，譬如调度，中断等，也能帮我们去追踪动态的内核函数，以及这些函数的调用栈还有栈的使用这些。它也能帮我们去追踪延迟，譬如中断被屏蔽，抢占被禁止的时间，以及唤醒一个进程之后多久开始执行的时间。

## 使用

### 首先要挂载debugfs

内核基本上已经已经都开起了debugfs/tracdfs支持，在`/sys/kernel/debug`目录下有一个tracing目录，新的内核则是挂载在`sys/kernel/tracing`，但是都可已经将目录连接到`/tracing`目录下进行统一。

### Function/Function_graph

可以看看ftrace支持哪些插件，

```shell
$ cat avaliable_tracers
hwlat blk mmiotrace function_graph wakeup_dl wakeup_rt wakeup function nop
```

使用最多的是`function`和`functions_graph`两个插件，如果不行用trace了，可以置为`nop`。

首先打开`function_graph`:

```shell
$ echo function_graph > current_tracer 	#开启function_graph的tracer
$ cat current_tracer					#查看当前的tracer
function_graph
```

然后这个tracer就开始工作了，会将相关的信息放在`trace`文件中，直接读取这个文件即可得到相关的信息。

也可以设定只跟踪特定的function

```shell
$ echo write > set_ftrace_fileter #输出是function
$ echo write > set_graph_function #输出是function_graph
#$echo 3 > max_graph_depth		  #图的深度
$ cat set_ftrace_filter
write
$ cat trace | head -n 15
...

#不需要跟踪这个函数：
$ echo '!write' > set_ftrace_filter # set_graph_function
#或者
$ echo write > set_ftrace_notrace
```

Function filter 的设置也支持 `*match`，`match*` ，`*match*` 这样的正则表达式，譬如我们可以 `echo '*lock*' < set_ftrace_notrace` 来禁止跟踪带 `lock` 的函数，`set_ftrace_notrace` 文件里面这时候就会显示：

```bash
cat set_ftrace_notrace
xen_pte_unlock
read_hv_clock_msr
read_hv_clock_tsc
update_persistent_clock
read_persistent_clock
set_task_blockstep
user_enable_block_step
...
```

## 启动/关闭

```shell
$ echo 1 > tracing_on
$ echo 0 > tracing_on
```

··· 待更新


