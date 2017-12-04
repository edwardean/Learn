## iOS 11 UIScrollView在页面push、pop时跳动的问题修复

背景：在iOS11系统上如果一个页面里有`UIScrollView`或者其子类的subView，同时满足该subView的top和view的top相等，
或者该subView的`topLayoutGuide`和view的`safeAreaLayoutGuide`的`topAnchor`相等时，在页面push和pop的过程中`UIScrollView`会有一个诡异的往上跳动的动画。

### 问题出现的场景
1. iOS11
2. 页面中至少有一个`UIScrollView`或者其子类的subView
3. subView满足top和view的top相等或者subView的`topLayoutGuide`和view的`safeAreaLayoutGuide`的`topAnchor`相等

### 现象研究
![1.gif](http://upload-images.jianshu.io/upload_images/10432-2128822af10800fb.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

经过调试发现，在页面push和pop时scrollView的contentOffset被移动了44。
进一步调试发现push和pop页面时`UIViewController`的

``` objc
- (void)viewSafeAreaInsetsDidChange;
```
方法都会被调用。

``` objc 
- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];  
 
    CGRect layoutFrame = self.view.safeAreaLayoutGuide.layoutFrame; 
    NSLog(@"%@", NSStringFromCGRect(layoutFrame));
}
```

打印结果：

* pop:

``` objc
 {{0, 44}, {375, 646}}
 {{0, 0}, {375, 690}}
```

* push:

``` objc
  {{0, 0}, {375, 690}}
  {{0, 44}, {375, 646}}
  {{0, 0}, {375, 690}}
```

这样会导致在push和pop时scrollView的contentOffset会往上移动44，所以出现了上述现象。
至于移动的44具体是什么值暂不清楚。

### 解决方案

#### 1. 设置`UIScrollView`的`contentInsetAdjustmentBehavior`属性为`UIScrollViewContentInsetAdjustmentNever`。

``` objc
self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
```

设置该属性确实能解决push和pop时scrollView跳动的问题，但是这样在iPhone X上会导致新的问题出现。

设置之前由于该属性的值是`UIScrollViewContentInsetAdjustmentAutomatic`，这样在iPhone X上系统能够自动处理好scrollView的contentInset，这样能保证iPhone X底部的虚拟Home键不会挡住ScrollView内容，在ScrollView滑动到底部时会自动留出safeArea的间距，确保内容不会和虚拟Home键重叠。

![1512377144893-image.png](http://upload-images.jianshu.io/upload_images/10432-128e768332af4d7a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

当设置成`UIScrollViewContentInsetAdjustmentNever`后系统便不再帮我们处理ScrollView的contentInset了，表现就是列表底部内容和滑动指示条会被虚拟Home键挡住。

![1512377186165-image.png](http://upload-images.jianshu.io/upload_images/10432-5d7ce4a7a63710f7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 2. 将VC的`edgesForExtendedLayout`属性设置成`UIRectEdgeNone`。

在SO上有人提到过用[这种方案](https://stackoverflow.com/questions/45573829/weird-uitableview-behaviour-in-ios11-cells-scroll-up-with-navigation-push-anima)来解决scrollview跳动问题，但是该方案在我们项目中测试并没有作用，所以没有采用这种方法。

#### 3. 在self.view中insert一个空白view。

在调试时偶然发现当UIView的subViews中的第一个subView不是UIScrollView或者其子类时在页面push和pop时便不再出现ScrollView跳动的问题，虽然为什么会这样的原因暂时未知。
但这确实给我们解决问题提供了很大思路，为此我们写了一个Hook的工具，hook住UIViewController的viewDidLoad方法，并在self.view中任意insert一个大小为0的不可见的view，这样便解决了这个问题。

``` objc

#ifdef __IPHONE_11_0
#import <Objc/runtime.h>
 
static const void *kFakeDotViewKey = &kFakeDotViewKey;
 
@implementation UIViewController (HLScrollViewJumpFix)
 
- (UIView *)fakeDotView
{
    return objc_getAssociatedObject(self, kFakeDotViewKey);
}
 
- (void)setFakeDotView:(UIView *)fakeDotView
{
    objc_setAssociatedObject(self, kFakeDotViewKey, fakeDotView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
 
+ (void)p_swizzledMethodWithOriginCls:(Class)originCls originSel:(SEL)originSel
                         overridedCls:(Class)overridedCls overridedSel:(SEL)overridedSel
{
    Method originalMethod = class_getInstanceMethod(originCls, originSel);
    Method overrideMethod = class_getInstanceMethod(overridedCls, overridedSel);
    if (originalMethod == NULL || overrideMethod == NULL) {
        return;
    }
    
    BOOL success = class_addMethod(originCls, originSel, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod));
    if (success) {
        class_replaceMethod(overridedCls, overridedSel, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
}
 
+ (void)load
{
    if (@available(iOS 11, *)) {
        Class vcCls = self;       
        [self p_swizzledMethodWithOriginCls:vcCls originSel:@selector(viewDidLoad)
                               overridedCls:vcCls overridedSel:@selector(p_viewDidLoad)];
    }
}
 
- (void)p_viewDidLoad
{
    [self p_viewDidLoad];
    Class cls = object_getClass(self);
    const char *clsName = class_getName(cls);
    NSString *clsNameString = [NSString stringWithUTF8String:clsName];
    //只处理业务层的VC，系统VC跳过
    if (![clsNameString hasPrefix:@"HL"]) {
        return;
    }
     
    UIView *fakeDotView = [self fakeDotView];
    if (fakeDotView) {
        return;
    }
     
    fakeDotView = [[UIView alloc] init];
    [self.view insertSubview:fakeDotView atIndex:0];   
    [self setFakeDotView:fakeDotView];
}
 
@end
 
#endif
```

经测试在VC的view中insert一个空白的view之后页面在pop或push时`UIScrollView`不再出现跳动的问题。