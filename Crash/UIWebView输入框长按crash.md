# UIWebView输入框长按crash

系统：
iOS 10或更低版本

复现步骤：
新建一个空的UIWebView工程，然后

- 加载含有输入框的网页(如 https://www.baidu.com)，输入任意几个字符，然后收起键盘；

- 长按网页其他位置的文本，出现放大镜后拖动到之前的输入框里，此时必现 crash

![](https://i.loli.net/2018/05/28/5b0b7bdc194f2.gif)

堆栈信息：

```
Application Specific Information:
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[_NSObserverList setCursorPosition:]: unrecognized selector sent to instance 0x1700bcf80'
 
Last Exception Backtrace:
0   CoreFoundation                      __exceptionPreprocess + 124
1   libobjc.A.dylib                     objc_exception_throw + 56
2   CoreFoundation                      __methodDescriptionForSelector + 0
3   CoreFoundation                      ___forwarding___ + 916
4   CoreFoundation                      _CF_forwarding_prep_0 + 92
5   UIKit                               -[_UIKeyboardTextSelectionController selectTextWithGranularity:atPoint:executionContext:] + 784
6   UIKit                               -[_UIKeyboardBasedNonEditableTextSelectionGestureController oneFingerForcePress:] + 1008
7   UIKit                               -[UIGestureRecognizerTarget _sendActionWithGestureRecognizer:] + 64
8   UIKit                               _UIGestureRecognizerSendTargetActions + 124
9   UIKit                               -[UIGestureRecognizer _forceLevelClassifier:currentForceLevelDidChange:] + 368
10  UIKit                               -[_UIForceLevelClassifier setCurrentForceLevel:] + 108
11  UIKit                               -[_UILinearForceLevelClassifier observeTouchWithForceValue:atTimestamp:withCentroidAtLocation:] + 156
12  UIKit                               __48-[_UIForceLevelClassifier receiveObservedValue:]_block_invoke + 160
13  UIKit                               -[_UITouchForceMessage ifObservation:ifReset:] + 304
14  UIKit                               -[_UIForceLevelClassifier receiveObservedValue:] + 280
15  Foundation                          -[_NSObserverList _receiveBox:] + 568
16  Foundation                          __68-[NSObject(DefaultObservationImplementations) receiveObservedValue:]_block_invoke + 64
17  Foundation                          -[NSObject(DefaultObservationImplementations) receiveObservedValue:] + 216
18  UIKit                               -[_UITouchForceObservable receiveObservedValue:] + 440
19  QuartzCore                          CA::Display::DisplayLinkItem::dispatch(unsigned long long) + 44
20  QuartzCore                          CA::Display::DisplayLink::dispatch_items(unsigned long long, unsigned long long, unsigned long long) + 444
21  IOKit                               IODispatchCalloutFromCFMessage + 372
22  CoreFoundation                      __CFMachPortPerform + 180
23  CoreFoundation                      __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 56
24  CoreFoundation                      __CFRunLoopDoSource1 + 436
25  CoreFoundation                      __CFRunLoopRun + 1840
26  CoreFoundation                      CFRunLoopRunSpecific + 444
27  GraphicsServices                    GSEventRunModal + 180
28  UIKit                               -[UIApplication _run] + 684
29  UIKit                               UIApplicationMain + 208
30  seagull                             main (main.m:14)
```

解决方案：

* 禁用webView长按出现放大镜功能。 该方法有副作用，用户可能无法长按复制文本。

```
[webView tt_evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';"
                 completionHandler:NULL];
```

* 参考蜜蜂团队的解决思路：

> 结合控制台输出的错误信息
> `[_UIKeyboardTextSelectionController setCursorPosition:]: message sent to deallocated instance 0x6080000f5a20`
> 
> 初步分析，可认为某个 UIGestureRecognizer 触发回调时，_UIKeyboardTextSelectionController 已经被释放，但 UIGestureRecognizerTarget 引用的指针未置空（可能由于 assign 修饰符导致），从而造成 bad access。
> 
> 考虑 crash 的原因是 _UIKeyboardTextSelectionController 对象销毁过早，因此可以使用变通的办法，即 hook 导致其销毁的方法（-[UIWebDocumentView useSelectionAssistantWithMode:] ），然后通过 GCD 延迟释放。

* Code

```
@implementation UIWebView (SelectionAssistantFix)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        //UIKeyboardTextSelectionController
        Class webDocumentViewCls = NSClassFromString(@"UIWebDocumentView");
        SEL swizzedSel = NSSelectorFromString(@"useSelectionAssistantWithMode:");

        SEL overrideSelector = @selector(p_useSelectionAssistantWithMode:);

        SwizzledMethod(webDocumentViewCls, self, swizzedSel, overrideSelector);
    });
}

- (void)p_useSelectionAssistantWithMode:(int)arg1
{
    NSString *key = @"webSelectionAssistant";
    if ([self respondsToSelector:NSSelectorFromString(key)]) {
        __block id assistant = [self valueForKey:key];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [assistant isKindOfClass:[NSObject class]];
            assistant = nil;
        });
    }
}
@end
```