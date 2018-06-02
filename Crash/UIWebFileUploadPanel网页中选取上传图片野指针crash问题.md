# UIWebFileUploadPanel网页中选取上传图片野指针crash问题

* 复现步骤 （UIWebView）

	微博：

![未命名.gif](https://i.loli.net/2018/05/25/5b07d3abb388b.gif)

   美团：

![meituan.gif](https://i.loli.net/2018/05/29/5b0ccfb8c75ed.gif)


* 堆栈信息

```
Exception Type:  EXC_BAD_ACCESS (SIGBUS)
Exception Codes: 0x00000000 at 0x000000098363da90
Crashed Thread:  0
 
Thread 0 name:  Dispatch queue: com.apple.main-thread
 
Thread 0 Crashed:
0   libobjc.A.dylib                 objc_msgSend + 28
1   UIKit                           +[UIViewController _viewControllerForFullScreenPresentationFromView:] + 40
2   UIKit                           -[UIWebFileUploadPanel _presentFullscreenViewController:animated:] + 88
3   UIKit                           __51-[UIDocumentMenuViewController _dismissWithOption:]_block_invoke.220 + 92
4   UIKit                           -[UIPresentationController transitionDidFinish:] + 1324
5   UIKit                           __56-[UIPresentationController runTransitionForCurrentState]_block_invoke_2 + 188
6   UIKit                           -[_UIViewControllerTransitionContext completeTransition:] + 116
7   UIKit                           -[UITransitionView notifyDidCompleteTransition:] + 252
8   UIKit                           -[UITransitionView _didCompleteTransition:] + 1240
9   UIKit                           -[UITransitionView _transitionDidStop:finished:] + 124
10  UIKit                           -[UIViewAnimationState sendDelegateAnimationDidStop:finished:] + 312
11  UIKit                           -[UIViewAnimationState animationDidStop:finished:] + 160
12  QuartzCore                      CA::Layer::run_animation_callbacks(void*) + 260
13  libdispatch.dylib               _dispatch_client_callout + 16
14  libdispatch.dylib               _dispatch_main_queue_callback_4CF + 1000
15  CoreFoundation                  __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 12
16  CoreFoundation                  __CFRunLoopRun + 1660
17  CoreFoundation                  CFRunLoopRunSpecific + 444
18  GraphicsServices                GSEventRunModal + 180
19  UIKit                           -[UIApplication _run] + 684
20  UIKit                           UIApplicationMain + 208
21  moma                            main (main.m:15)
22  libdyld.dylib                   start + 4
```

* 原因

	在一个可以上传图片照片的wenView页面中唤起UIWebFileUploadPanel的同时将web页面pop掉，这时UIWebFileUploadPanel对象中持有的documentView(documentView是一个assign类型)就会变为野指针，再去访问这个野指针就会crash。
	
	
* 解决方案

	hook住UIWebFileUploadPanel中documentView的set方法，用一个weak对象持有它，理论上当web页面消失之后这个weak对象会自动被置为nil。通过这个原理来判断documentView对象是否已经被销毁，如果已经被销毁则不再做后续操作，避免野指针crash的发生。
		

* Code

```
#import <objc/runtime.h>

__weak id privateDocumentView = nil;

@implementation NSObject (DEFFixWebFileUploadPannelCrash)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *fileUploadPanel = @"UIWebFileUploadPanel";
        Class fileUploadCls = NSClassFromString(fileUploadPanel);
        SEL panelSetterSwizzedSel = NSSelectorFromString(@"setDocumentView:");
        SEL panelSwizzedSel = NSSelectorFromString(@"_presentFullscreenViewController:animated:");
        
        SEL overrideSelector = @selector(p_presentFullscreenViewController:animated:);
        SEL orerrideSetDocumentSel = @selector(p_setDocumentView:);
        
        SwizzledMethod(fileUploadCls, self, panelSwizzedSel, overrideSelector);
        SwizzledMethod(fileUploadCls, self, panelSetterSwizzedSel, orerrideSetDocumentSel);
    });
}

- (void)p_presentFullscreenViewController:(id)controller animated:(BOOL)animated
{
    if (!privateDocumentView) {
        return;
    }
    [self p_presentFullscreenViewController:controller animated:animated];
}

- (void)p_setDocumentView:(id)documentView
{
    privateDocumentView = documentView;
    [self p_setDocumentView:documentView];
}

@end
```