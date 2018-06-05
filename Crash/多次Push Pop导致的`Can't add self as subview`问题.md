## 多次Push Pop导致的`Can't add self as subview`问题

* 崩溃堆栈

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Can't add self as subview'
*** First throw call stack:
(
	0   CoreFoundation                      0x000000010ec2df35 __exceptionPreprocess + 165
	1   libobjc.A.dylib                     0x000000010e8c8bb7 objc_exception_throw + 45
	2   CoreFoundation                      0x000000010ec2de6d +[NSException raise:format:] + 205
	3   UIKit                               0x000000010b351982 -[UIView(Internal) _addSubview:positioned:relativeTo:] + 123
	4   UIKit                               0x000000010b2d0b19 __53-[_UINavigationParallaxTransition animateTransition:]_block_invoke + 1814
	5   UIKit                               0x000000010b34c5ce +[UIView(Animation) performWithoutAnimation:] + 65
	6   UIKit                               0x000000010b2d0072 -[_UINavigationParallaxTransition animateTransition:] + 1225
	7   UIKit                               0x000000010b424e6c -[UINavigationController _startCustomTransition:] + 3038
	8   UIKit                               0x000000010b4303fe -[UINavigationController _startDeferredTransitionIfNeeded:] + 386
	9   UIKit                               0x000000010b430f47 -[UINavigationController __viewWillLayoutSubviews] + 43
	10  UIKit                               0x000000010b576509 -[UILayoutContainerView layoutSubviews] + 202
	11  UIKit                               0x000000010b354973 -[UIView(CALayerDelegate) layoutSublayersOfLayer:] + 521
	12  QuartzCore                          0x000000010f589de8 -[CALayer layoutSublayers] + 150
	13  QuartzCore                          0x000000010f57ea0e _ZN2CA5Layer16layout_if_neededEPNS_11TransactionE + 380
	14  QuartzCore                          0x000000010f57e87e _ZN2CA5Layer28layout_and_display_if_neededEPNS_11TransactionE + 24
	15  QuartzCore                          0x000000010f4ec63e _ZN2CA7Context18commit_transactionEPNS_11TransactionE + 242
	16  QuartzCore                          0x000000010f4ed74a _ZN2CA11Transaction6commitEv + 390
	17  UIKit                               0x000000010b2d814d _UIApplicationHandleEventQueue + 2035
	18  CoreFoundation                      0x000000010eb63551 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 17
	19  CoreFoundation                      0x000000010eb5941d __CFRunLoopDoSources0 + 269
	20  CoreFoundation                      0x000000010eb58a54 __CFRunLoopRun + 868
	21  CoreFoundation                      0x000000010eb58486 CFRunLoopRunSpecific + 470
	22  GraphicsServices                    0x0000000110c659f0 GSEventRunModal + 161
	23  UIKit                               0x000000010b2db420 UIApplicationMain + 1282
	24  moma-beta                           0x00000001071abe1f main + 111
	25  libdyld.dylib                       0x000000011068f145 start + 1
)
libc++abi.dylib: terminating with uncaught exception of type NSException

```

* 复现步骤

![push pop.gif](https://i.loli.net/2018/06/05/5b163ee29f163.gif)


* 修复方案： Hook `UINavigationController`的

`- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;`

 和
 
`- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated;`

 两个方法。
 
 * Code

 ```
 	@implementation UINavigationController (PushPopCrashFix)

	+ (void)load {
    	static dispatch_once_t onceToken;
    	dispatch_once(&onceToken, ^{
        	SwizzledMethod(self, self, @selector(popViewControllerAnimated:), @selector(p_PopViewControllerAnimated:));
        	SwizzledMethod(self, self, @selector(pushViewController:animated:), @selector(p_PushViewController:animated:));
    	});
	}

	- (BOOL)prohibitPushPop {
    	return [objc_getAssociatedObject(self, @selector(prohibitPushPop)) boolValue];
	}

	- (void)setProhibitPushPop:(BOOL) prohibitPushPop {
    	objc_setAssociatedObject(self, @selector(prohibitPushPop), @(prohibitPushPop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	- (UIViewController *)p_FixPopViewControllerAnimated:(BOOL)animated {
   	 	if (self.prohibitPushPop) {
        	return nil;
    	}

    	self.prohibitPushPop = YES;
    	UIViewController *vc = [self DPPFixPopViewControllerAnimated:animated];
    	[CATransaction setCompletionBlock:^{
        	self.prohibitPushPop = NO;
    	}];
    	return vc;
}

	- (void)p_PushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    	if (self.prohibitPushPop) {
        	return;
    	}

    	self.prohibitPushPop = YES;
    	[self DPPFixPushViewController:viewController animated:animated];
    	[CATransaction setCompletionBlock:^{
        	self.prohibitPushPop = NO;
    	}];
}

	@end

 ```