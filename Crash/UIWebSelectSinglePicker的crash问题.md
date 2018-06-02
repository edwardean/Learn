# UIWebSelectSinglePicker的crash问题

* 复现步骤：

用UIWebView打开这个[测试网页](http://www.w3school.com.cn/tiy/t.asp?f=html_select_name)，将其中`<select></select>`节点中所有的option节点删除，会出现一个空白的UIPickerView，如下图：

![IMG_0630.PNG](https://i.loli.net/2018/05/25/5b07c776d7838.png)

在这个空白的picker中随便划几下再点完成按钮便会crash。

* 崩溃堆栈：

```
Date/Time:       2017-06-16 18:15:02.000 +0800
OS Version:      iOS 10.2 (14C92)
Report Version:  104
 
Exception Type:  EXC_CRASH (SIGABRT)
Exception Codes: 0x00000000 at 0x0000000000000000
Crashed Thread:  0
 
Application Specific Information:
*** Terminating app due to uncaught exception 'NSRangeException', reason: '*** -[__NSArrayM objectAtIndex:]: index 0 beyond bounds for empty array'
 
Thread 0 name:  Dispatch queue: com.apple.main-thread
 
Thread 0 Crashed:
0   CoreFoundation                  __exceptionPreprocess + 124
1   libobjc.A.dylib                 objc_exception_throw + 56
2   CoreFoundation                  -[__NSArrayM removeObjectAtIndex:] + 0
3   UIKit                           -[UIWebSelectSinglePicker pickerView:didSelectRow:inComponent:] + 72
4   UIKit                           -[UIPickerView _sendSelectionChangedForComponent:notify:] + 116
5   UIKit                           -[UIPickerView _sendSelectionChangedFromTable:notify:] + 344
6   UIKit                           -[UIPickerTableView _scrollingFinished] + 188
7   UIKit                           -[UIPickerTableView scrollViewDidEndDecelerating:] + 28
8   UIKit                           -[UIScrollView(UIScrollViewInternal) _scrollViewDidEndDeceleratingForDelegate] + 132
9   UIKit                           -[UIScrollView(UIScrollViewInternal) _stopScrollDecelerationNotify:] + 332
10  UIKit                           -[UIScrollView _smoothScrollWithUpdateTime:] + 2356
11  QuartzCore                      CA::Display::DisplayLinkItem::dispatch(unsigned long long) + 44
12  QuartzCore                      CA::Display::DisplayLink::dispatch_items(unsigned long long, unsigned long long, unsigned long long) + 444
13  IOKit                           IODispatchCalloutFromCFMessage + 372
14  CoreFoundation                  __CFMachPortPerform + 180
15  CoreFoundation                  __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 56
16  CoreFoundation                  __CFRunLoopDoSource1 + 436
17  CoreFoundation                  __CFRunLoopRun + 1840
18  CoreFoundation                  CFRunLoopRunSpecific + 444
19  GraphicsServices                GSEventRunModal + 180
20  UIKit                           -[UIApplication _run] + 684
21  UIKit                           UIApplicationMain + 208
22  moma                            main (main.m:15)
23  libdyld.dylib                   start + 4
```

* crash分析：

 * 首先看看`-[UIWebSelectSinglePicker pickerView:didSelectRow:inComponent:]`方法中具体发生崩溃的逻辑：
 
	![1527236825624-image.png](https://i.loli.net/2018/05/25/5b07c918c2029.png)

图中在对`optionItems`数组进行`objectAtIndex`时直接将方法第二个参数r15传了进去，而此时`optionItems`是个空数组，所以发生了崩溃。

* 解决方法：

按照上面的分析如果我们去hook`-[UIWebSelectSinglePicker pickerView:didSelectRow:inComponent:]`方法似乎不太靠谱，这个方法太长，我们继续往上找在哪里调用了该方法：

```
void -[UIPickerView _sendSelectionChangedForComponent:notify:](void * self, void * _cmd, long long arg2, bool arg3) {
    rcx = arg3;
    r14 = arg2;
    rbx = self;
    if ((rbx->_pickerViewFlags & 0x8) != 0x0) {
            rcx = rcx ^ 0x1;
            if (rcx == 0x0) {
                    rax = [rbx selectedRowInComponent:r14];
                    [rbx->_delegate pickerView:rbx didSelectRow:rax inComponent:r14];
            }
    }
    rdi = rbx;
    rdx = r14;
    [rdi _noteScrollingFinishedForComponent:rdx];
    return;
}
```

看到这里思路就清晰了，原来崩溃的`UIWebSelectSinglePicker `是`UIPickerView `的`delegate`，那我们就行调用`delegate`的地方入手进行防护。

* Code

代码很简单，直接贴在这里。
	

```
#import <objc/runtime.h>

@implementation UIPickerView (DEFWebSinglePickCrash)

+ (void)load
{
    
    SEL originalSelector = @selector(_sendSelectionChangedForComponent:notify:);
    
    SEL overrideSelector = @selector(swizzle_sendSelectionChangedForComponent:notify:);
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method overrideMethod = class_getInstanceMethod(self, overrideSelector);
    
    BOOL success = class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod));
    if (success) {
        class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
}

- (void)swizzle_sendSelectionChangedForComponent:(int)arg1 notify:(BOOL)arg2
{
    Class class = NSClassFromString(@"UIWebSelectSinglePicker");
    if ([self isKindOfClass:class]) {
        NSArray *optionItems = [self valueForKey:@"_optionItems"];
        if (optionItems.count > 0) {
            [self swizzle_sendSelectionChangedForComponent:arg1 notify:arg2];
        }
    } else {
        [self swizzle_sendSelectionChangedForComponent:arg1 notify:arg2];
    }
}

@end

```