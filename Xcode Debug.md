
# Xcode Debug Toolset
## print
* 简写成p, pri, ptin
* po(print object)可以打印对象的description方法的结果
* 打印不同格式可以用p/x number打印十六进制，p/t number打印二进制，p/c char打印字符。这里是完整清单https://sourceware.org/gdb/onlinedocs/gdb/Output-Formats.html
* `(lldb) po [0x1234 _ivarDescription]`
* `(lldb) po [0x1234 _shortMethodDescription]`
* `(lldb) po [0x1234 _methodDescription]`
* `(lldb) po [[UIWindow keyWindow] recursiveDescription]`打印window所有的视图层级
* `(lldb) po [[[UIWindow keyWindow] rootViewController] _printHierarchy]`打印controller的视图层级


##### 调试寄存器中的变量：
* `(lldb) register read` 打印寄存器中的值
* `(lldb) register read $arg1 $arg2` 打印参数
* `(lldb) reg read rax` 读取rax寄存器（返回值）的内容
* `(lldb) disassemble --frame` 将汇编代码反汇编成伪代码

|platform|recriver|SEL|Arg1|Arg2|return value|
|---|---|---|---|---|---|
|x86_64|rdi或者`$rbp+16`|rsi或者`$rbp+24`|rdx或者`$rbp+32`|rcx或者`$rbp+40`|rax|
|arm64|x0|x1|x2|x3|
|arm|r0|r1|r2|r3|



## erpression
* 简写成 e，执行代码
* `(lldb) e [((UIView *)0x06ae2) setBackgroundColor:[UIColor redColor]]`更改一个view的背景颜色
* `(lldb) e class_getInstanceMethod([MyViewController class], @selector(layoutSubviews))`查看Method
* `(lldb) e BOOL $a = YES`创建一个变量，变量名要以`$`作前缀

## Breakpoint
### 命令行添加断点
* `(lldb) br set -a 0x01234`
* `(lldb) br set -r "UIView"`

### 通用断点
* All Exceptions 异常断点
* `UIViewAlertForUnsatisfiableConstraints` :
  在遇到Autolayout约束冲突时会触发该断点
  
* `UIApplicationMain`:

  **Debugger Command:**`e @import UIKit`
  
  这样在控制台中可以直接打印view的frame:
  `p [view bounds]`
  
	![](http://chuantu.biz/t5/143/1500545154x1730513932.png)

### 符号断点
 ![](http://chuantu.biz/t5/143/1500545827x1730513932.png)

### 将断点添加到User Breakpoints中，可以跨工程共享

 ![s](https://pspdfkit.com/images/blog/2017/user-breakpoints-in-xcode/move-to-user@2x-d63238f8.png)
 
## watchpoint
  监视内存地址发生读写

* `(lldb) watchpoint s e read 0x7f8c519b4600`

* `(lldb) watchpoint s e read_write 0x7f8c519b4600`

* `(lldb) watchpoint set e -- 0x7f8b6ccd11b0` 

监视vMain变量什么时候被重写了，监视这个地址什么时候被写入

```
(lldb) p (ptrdiff_t)ivar_getOffset((struct Ivar *)class_getInstanceVariable([MyView class], "vMain"))
(ptrdiff_t) $0 = 8
(lldb) watchpoint set expression -- (int *)$myView + 8
Watchpoint created: Watchpoint 3: addr = 0x7fa554231340 size = 8 state = enabled type = w
new value: 0x0000000000000000
```
## image lookup
* `(lldb) image lookup -s UIView` 打印UIView所在的映像文件
* `(lldb) image lookup -n setCenterPlaceholder`打印某个方法所在的映像文件
* `(lldb) image list UIKit`
* 更多用法参考 `help image lookup`


## xcode 环境变量
* `OBJC_PRINT_REPLACED_METHODS YES` 打印重名方法
* `DYLD_PRINT_STATISTICS 1` 打印App启动时DYLD加载时长


##参考
* https://developer.apple.com/library/content/technotes/tn2239/_index.html
* https://www.objc.io/issues/19-debugging/debugging-case-study/
* https://pspdfkit.com/blog/2017/user-breakpoints-in-xcode/