## iOS11 UICollectionView的header被scrollIndicator遮挡问题

现象：在iOS11系统上，`UICollectionView`的section headerView会被scrollIndicator遮挡，iOS10或iOS10以前系统则没有问题。

iOS 11:

![iOS11.gif](http://upload-images.jianshu.io/upload_images/10432-266a2e70b34c42f8.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

iOS 10:

![iOS10.gif](http://upload-images.jianshu.io/upload_images/10432-2709e3a0d1290206.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 解决方案
1. 创建一个CALayer子类，重新`- (CGFloat)zPosition;`方法并返回0；
2. 重写SectionHeaderView的`+ (Class)layerClass;`方法；并返回前一步中自定义的layer；

``` objc
@interface HLTagCollectionHeaderLayer : CALayer
@end

@implementation HLTagCollectionHeaderLayer
- (CGFloat)zPosition {
    return 0;
}
@end

@implementation HLTagCollectionHeaderView
+ (Class)layerClass {
    if (@available(iOS 11.0, *)) {
        return [HLTagCollectionHeaderLayer class];
    }
    return [super layerClass];
}
@end
```

> 经测试该问题在iOS 11.1.2以下版本上才有，苹果已经在iOS11.1.2版本解决该问题。