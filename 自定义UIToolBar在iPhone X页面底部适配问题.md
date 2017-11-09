# 自定义UIToolBar在iPhone X页面底部适配问题

先来看两张在iPhone X上面UIToolBar的截图：

![](https://i.loli.net/2017/11/09/5a03b6835876e.png)

![](https://i.loli.net/2017/11/09/5a03b6a5482c8.png)

两张图中底部都是UIToolBar，不同的是第一张是UINavigationController自带的toolBar，
第二张是自定义的toolBar。

第一张图中部分实现代码：

``` objc
[self.navigationController setToolbarHidden:NO animated:NO];
[self.navigationController.toolbar setBarStyle:UIBarStyleDefault];
self.navigationController.toolbar.translucent = NO;
self.navigationController.toolbar.tintColor = HEXCOLOR(0xFFD2D2D2);
self.navigationController.toolbar.barTintColor = HEXCOLOR(0xFFD2D2D2);
 
UIBarButtonItem *previewButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_previewButton];
UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_doneButton];
UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
 
[self setToolbarItems:@[previewButtonItem, spaceButtonItem, doneButtonItem]];
```

第二张图中自定义实现UIToolBar的代码：

``` objc
    UIToolbar *bottomToolBar = [[UIToolbar alloc] init];
    [self.view addSubview:bottomToolBar];
  
    UIBarButtonItem *leftFixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                        target:nil action:nil];
    UIBarButtonItem *middleSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                        target:nil action:nil];
    UIBarButtonItem *rightFixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                     target:nil action:nil];
    leftFixedSpaceItem.width = rightFixedSpaceItem.width = -10;
    UIBarButtonItem *reCaptureButtonItem = [[UIBarButtonItem alloc] initWithCustomView:reAdd];
    UIBarButtonItem *submitButtonItem = [[UIBarButtonItem alloc] initWithCustomView:submit];
    [bottomToolBar setItems:@[leftFixedSpaceItem,reCaptureButtonItem,middleSpaceItem,submitButtonItem,rightFixedSpaceItem]];
 
    [bottomToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self.view);
    }];
```

为什么自定义toolBar确不能在iPhone X上自动对safeArea适配呢？
后来发现UIToolBar里面有一些私有subview的高度并不是和toolBar本身一样，toolBar高度是49，_UIBarBackground的高度却是83,

![](https://i.loli.net/2017/11/09/5a03b976c80b6.jpeg)
![](https://i.loli.net/2017/11/09/5a03b8133f9da.png)

是不是这个_UIBarBackground的私有subView被当做了toolBar的baselineView了呢，所以决定按这个思路重新对自定义toolBar改一下约束：
 
``` objc
[bottomToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
    make.leading.trailing.equalTo(self.view);
}];
//在iOS11上让UIToolBar的lastBaselineAnchor等于view的safeAreaLayoutGuide的bottomAnchor
if (@available(iOS 11.0, *)) {
    [bottomToolBar.lastBaselineAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
} else {
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:bottomToolBar
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:0]];
}
```

这样约束果然有用，效果和navigationController自带的toolBar效果一样了：
![](https://i.loli.net/2017/11/09/5a03b8133c188.png)
