---
title: Python-tkinter小尝试
date: 2021-07-05 19:02:13
tags:
- Python
- tkinter
---
写了一个即时翻译的小软件，应该还要加上监控线程，死亡后重启的模块。
<!-- more -->
## Python

### 新建一个线程

```python
import threading
	
th = threading.Thread(func,args)
#th = threading.Thread(pirnt,"hello world")
```

## Tkinter基础内容

线程中不可以修改UI的内容，可以用管道，共享队列等方法与主线程通信，然后在主线程中对UI的信息进行修改。

直接上代码，一个实时翻译的小工具

```python
from googletrans import Translator
import tkinter as tk
import win32clipboard as w
import queue


#定义了一个根窗口命名为win
win = tk.Tk()
win.title('实时翻译')
win.wm_attributes('-topmost', 1)
#这个队列用于当子进程检查到剪切板的内容发生了变化的时候将新内容put进队列。
qu = queue.Queue()

#检查剪切板的内容有没有变化。每次500ms时间间隔
def checkout_clip_thread (original):
    temp = get_text()
    if temp != original:
        original = temp
        #将新的剪切板的内容放进队列，主进程从队列中取消息更改UI内容
        qu.put(original)
        # print(qu)
    # 一个循环
    win.after(500,checkout_clip_thread,original)

#将粘贴板的内容显示到程序的两个窗口上
def checkout_clip ():
    while not qu.empty():
        temp = qu.get()
        print(temp)
        sourcetext.delete('1.0', 'end')
        sourcetext.insert(tk.END, temp)
        targettext.delete('1.0', 'end')
        targettext.insert(tk.END, translater(temp))
    # 一个循环，循环获取队列中的消息
    # 用after不会造成主进程的阻塞。
    win.after(500,checkout_clip)

#获取剪切板的内容
def get_text ():
    w.OpenClipboard()
    d = str(w.GetClipboardData()).replace('\r\n', ' ')
    # d = str(w.GetClipboardData())
    w.CloseClipboard()
    return d

#用google的api获取字符串的翻译
def translater(d):
    ttt = Translator(service_urls=['translate.google.cn'])
    tt = ttt.translate(d, src='en', dest='zh-cn')
    return tt.text

#双击文本框进行更新粘贴板内容操作
def update (e):
    # print('update')
    sourcetext.delete('1.0','end')
    sourcetext.insert(tk.END,get_text())
    targettext.delete('1.0','end')
    targettext.insert(tk.END,translater(get_text()))

#双击文本框进行更新翻译窗口的内容，可以修改内容框之后进行翻译
def update2 (e):
    # print('update2')
    s = sourcetext.get('0.0','end')
    targettext.delete('1.0', 'end')
    targettext.insert(tk.END, translater(s))

if __name__=='__main__':

    sourcetext = tk.Text(win,height=10)
    targettext = tk.Text(win,height=10)
    sourcetext.insert(tk.END, get_text())
    targettext.insert(tk.END, get_text())

    sourcetext.pack()
    targettext.pack()

    # 绑定事件
    sourcetext.bind('<Double-Button-1>', update)
    targettext.bind('<Double-Button-1>', update2)
    win.after(500,checkout_clip_thread,get_text())
    win.after(500,checkout_clip())
    win.mainloop()


```
