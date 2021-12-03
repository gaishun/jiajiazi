---
title: shell编程
date: 2021-12-03 16:23:37
tags:
- linux
- shell
---

讲道理shell编程对自动化还是蛮重要的，所以特意写一个文档整理一下语法。

<!-- more -->
### 变量

```shell
your_name="asdf"
your_name="fdsa" #可以重新定义

for file in `ls /`
for file in $(ls /)#两者得到的结果一样
for skill in Ada Coffe Action Java #可以在这里枚举

echo $file
echo ${file} #{}是为了确认边界

readonly url="www.baidu.com" #制度变量
unset url #删除变量

```

### 字符串

```shell
#单引号
其中的变量无效
单引号字符串中不能单独出现一个单引号，转义也不行，但是可以成对出现

#双引号
其中可以有变量
可以出现转义字符

#拼接
your_name="shun"
	#单引号
	real_name='gai'$your_name'!'
	real_name='gai${your_name}'#不行
	#双引号
	real_name="gai"$your_name
	real_name="gai${your_name}"
	
#长度
	echo ${#your_name} 
	
#提取子串
	echo ${your_name:1:3} #输出hun
	
#查找字串
	expr index "$your_name" st #查找第一个s 或 t的位置，这里输出0
```

### 数组

```shell
array=(1 2 3 4 5)
array[0]=9

${array[2]}
${array{@}}	#array所有元素

${#array[@]}  ${#array[*]} #数组长度
${#array[n]}	#第n个元素的长度
```

### 多行注释

```shell
:<<"
annotations
"

:<<EOF
annotations
EOF
```

### 传递参数

```shell
$0 $1 $2 $3
$0: 执行的文件名，软连接直呼牛逼，其他的就是第一二三个参数。

$#:传递到脚本的参数个数
$*:用一个单字符串显示所有脚本传递的参数，"$*"使用 -> "$1 $2 $3 ..."
$$:脚本运行的ID号
$!:后台运行的最后一个进程的ID号
$@:与$*相似，"$@" -> "$1" "$2" "$3"
$-:显示shell当前使用的选项，与set命令相同
$?:显示最后命令的退出状态，0表示没有错误。
```

### 基本运算符

不能直接写2+2，要用expr命令

```shell
val = `expr 2 + 2` 		# + - * / % 五个都这样用
a = $b #变量赋值 			 # = 这样用
[ $a == $b ]			    # == != 两个这样用，一定要有空格
```

### 关系运算符

```
-eq #相等返回true
-ne #不相等返回true
-gt #左边大于右边返回true
-lt #左边小于右边返回true
-ge #左边大于等于右边返回true
-le #左边小于等于右边返回true
#使用： [ $a -eq $b ]
```

### 布尔运算

```shell
!		#[ ! false ]
-o	#[ $a -lt 20 -o $b -gt 100 ]
-a  #[ $a -lt 20 -a $b -gt 100 ]

$$	#[[ $a -lt 20 && $b -gt 100 ]]
||	#[[ $a -lt 20 || $b -gt 100 ]]
```

### 字符串运算符

```shell
= 		#检测相等 									 [ $a = $b ]
!= 		#检测不相等									[ $a != $b ]
-z 		#检测长度是否是0，是0返回true 	[ -z $a ]
-n 		#检测长度是否不是0，不是0返回true [ -n $a ]
$			#检测是否为空，不空返回true		[$a]
```

### 文件描述符

| 操作符  | 说明                                                         | 举例                      |
| :------ | :----------------------------------------------------------- | :------------------------ |
| -b file | 检测文件是否是块设备文件，如果是，则返回 true。              | [ -b $file ] 返回 false。 |
| -c file | 检测文件是否是字符设备文件，如果是，则返回 true。            | [ -c $file ] 返回 false。 |
| -d file | 检测文件是否是目录，如果是，则返回 true。                    | [ -d $file ] 返回 false。 |
| -f file | 检测文件是否是普通文件（既不是目录，也不是设备文件），如果是，则返回 true。 | [ -f $file ] 返回 true。  |
| -g file | 检测文件是否设置了 SGID 位，如果是，则返回 true。            | [ -g $file ] 返回 false。 |
| -k file | 检测文件是否设置了粘着位(Sticky Bit)，如果是，则返回 true。  | [ -k $file ] 返回 false。 |
| -p file | 检测文件是否是有名管道，如果是，则返回 true。                | [ -p $file ] 返回 false。 |
| -u file | 检测文件是否设置了 SUID 位，如果是，则返回 true。            | [ -u $file ] 返回 false。 |
| -r file | 检测文件是否可读，如果是，则返回 true。                      | [ -r $file ] 返回 true。  |
| -w file | 检测文件是否可写，如果是，则返回 true。                      | [ -w $file ] 返回 true。  |
| -x file | 检测文件是否可执行，如果是，则返回 true。                    | [ -x $file ] 返回 true。  |
| -s file | 检测文件是否为空（文件大小是否大于0），不为空返回 true。     | [ -s $file ] 返回 true。  |
| -e file | 检测文件（包括目录）是否存在，如果是，则返回 true。          | [ -e $file ] 返回 true。‘ |

### test，用于检查某个条件是否成立

```shell
#两个数
num1=100
num2=100
if test $[num1] -eq $[num2]
then
    echo '两个数相等！'
else
    echo '两个数不相等！'
fi
#字符串
num1="ru1noob"
num2="runoob"
if test $num1 = $num2
then
    echo '两个字符串相等!'
else
    echo '两个字符串不相等!'
fi
#文件
cd /bin
if test -e ./bash
then
    echo '文件已存在!'
else
    echo '文件不存在!'
fi
#条件
cd /bin
if test -e ./notFile -o -e ./bash
then
    echo '至少有一个文件存在!'
else
    echo '两个文件都不存在'
fi
#if elif else fi
if
then 
...
elif
then
...
else
...
fi
```

### 循环

```shell
for var in item1 item2 ... itemN
do
    command1
    command2
    ...
    commandN
done

#!/bin/bash
int=1
while(( $int<=5 ))
do
    echo $int
    let "int++"
done

echo '按下 <CTRL-D> 退出'
echo -n '输入你最喜欢的网站名: '
while read FILM
do
    echo "是的！$FILM 是一个好网站"
done

#break 和 continue 都可以用
```

### 函数

```shell
[ function ] funname [()]
{
    action;
    [return int;]
}

#ex:
funWithReturn(){
    echo "这个函数会对输入的两个数字进行相加运算..."
    echo "输入第一个数字: "
    read aNum
    echo "输入第二个数字: "
    read anotherNum
    echo "两个数字分别为 $aNum 和 $anotherNum !"
    return $(($aNum+$anotherNum))
}
funWithReturn
echo "输入的两个数字之和为 $? !"#用$?获得返回值

#参数，不用显示写在()中，还使用$1,$2这样调用
funWithParam 1 2 3 4 5 6 7 8 9 34 73

```

### 重定向

| 命令            | 说明                                               |
| :-------------- | :------------------------------------------------- |
| command > file  | 将输出重定向到 file。                              |
| command < file  | 将输入重定向到 file。                              |
| command >> file | 将输出以追加的方式重定向到 file。                  |
| n > file        | 将文件描述符为 n 的文件重定向到 file。             |
| n >> file       | 将文件描述符为 n 的文件以追加的方式重定向到 file。 |
| n >& m          | 将输出文件 m 和 n 合并。                           |
| n <& m          | 将输入文件 m 和 n 合并。                           |
| << tag          | 将开始标记 tag 和结束标记 tag 之间的内容作为输入。 |

*需要注意的是文件描述符 0 通常是标准输入（STDIN），1 是标准输出（STDOUT），2 是标准错误输出（STDERR）。*

重定向还可以深入一点：

```shell
command 2>file # stderr 重定向到 file
command 2>>file	#stderr 追加到 file 文件末尾
command > file 2>&1 或 command >> file 2>&1 # stdout 和 stderr 合并后重定向到 file
command < file1 >file2 #command 命令将 stdin 重定向到 file1，将 stdout 重定向到 file2。
```

### Here Document

```shell
command << delimiter
    document
delimiter
#作用是将两个 delimiter 之间的内容(document) 作为输入传递给 command。
#结尾的delimiter 一定要顶格写，前面不能有任何字符，后面也不能有任何字符，包括空格和 tab 缩进。
#开始的delimiter前后的空格会被忽略掉。
```


