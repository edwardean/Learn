# 3D Touch功能在iOS9系统上的crash

* 复现步骤：在UIImagePickController系统相册collection页面上随便长按任意一张图片便会crash
* 复现机型：有3D Touch功能的机型（6s以后的设备）
* 堆栈信息：

```
Exception Type:  EXC_CRASH (SIGABRT)
Exception Codes: 0x00000000 at 0x0000000000000000
Crashed Thread:  0
 
Application Specific Information:
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '+[NSObject previewingContext:viewControllerForLocation:]: unrecognized selector sent to class 0x19f34e020'
 
Thread 0 name:  Dispatch queue: com.apple.main-thread
 
Thread 0 Crashed:
0   CoreFoundation                  __exceptionPreprocess + 124
1   libobjc.A.dylib                 objc_exception_throw + 56
2   CoreFoundation                  __CFExceptionProem + 0
3   UIKit                           -[UICollectionViewController previewingContext:viewControllerForLocation:] + 172
4   UIKit                           -[_UIViewControllerPreviewSourceViewRecord previewInteractionController:viewControllerForPreviewingAtPosition:inView:presentingViewController:] + 248
5   UIKit                           -[UIPreviewInteractionController startInteractivePreviewAtLocation:inView:] + 224
6   UIKit                           -[UIPreviewInteractionController startInteractivePreviewWithGestureRecognizer:] + 136
7   UIKit                           -[UIPreviewInteractionController _handleRevealGesture:] + 100
8   UIKit                           _UIGestureRecognizerSendTargetActions + 164
9   UIKit                           _UIGestureRecognizerSendActions + 172
10  UIKit                           -[UIGestureRecognizer _updateGestureWithEvent:buttonEvent:] + 784
11  UIKit                           ___UIGestureRecognizerUpdate_block_invoke898 + 72
12  UIKit                           _UIGestureRecognizerRemoveObjectsFromArrayAndApplyBlocks + 372
13  UIKit                           _UIGestureRecognizerUpdate + 2404
14  UIKit                           -[UIWindow _sendGesturesForEvent:] + 1132
15  UIKit                           -[UIWindow sendEvent:] + 764
16  UIKit                           -[UIApplication sendEvent:] + 248
17  UIKit                           _UIApplicationHandleEventQueue + 5528
18  CoreFoundation                  __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 24
19  CoreFoundation                  __CFRunLoopDoSources0 + 540
20  CoreFoundation                  __CFRunLoopRun + 724
21  CoreFoundation                  CFRunLoopRunSpecific + 384
22  GraphicsServices                GSEventRunModal + 180
23  UIKit                           UIApplicationMain + 204
24  moma                            main (main.m:15)
25  libdyld.dylib                   start + 4
```

* 修复方式：hook `UICollectionViewController`中的`previewingContext:viewControllerForLocation:`方法并返回nil即可

* Code

```
#import <objc/runtime.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(ver)    ([[[UIDevice currentDevice] systemVersion] compare:@#ver options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(ver)                   ([[[UIDevice currentDevice] systemVersion] compare:@#ver options:NSNumericSearch] == NSOrderedAscending)


@implementation UICollectionViewController (DEF3DTouchCrashFix)

+ (void)load
{
	 //经测试iOS 9.3版本不再有该问题
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(9.0)
        && SYSTEM_VERSION_LESS_THAN(9.3)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            SEL originalSelector = @selector(previewingContext:viewControllerForLocation:);
            SEL overrideSelector = @selector(p_previewingContext:viewControllerForLocation:);
            
            Method originalMethod = class_getInstanceMethod(self, originalSelector);
            Method overrideMethod = class_getInstanceMethod(self, overrideSelector);
            
            if (!originalMethod) {
                return;
            }
            
            BOOL success = class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod));
            if (success) {
                class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, overrideMethod);
            }
        });
    }
}

- (UIViewController *)p_previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    return nil;
}

@end
```