## iOS 12 CALayer bounds contains NaN

* iOS 12最近总是出现这种崩溃:

```
 *** Terminating app due to uncaught exception 'CALayerInvalidGeometry', reason: 'CALayer bounds contains NaN: [0 0; 0 nan]'
```

经过排查原因发现均是跟`UITableView`的`tableHeaderView`设置相关。

下面是一段设置tableView的header的逻辑:

```
- (void)addHeaderView
{
    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:self.searchBar];
    self.orgFilterTable.tableHeaderView = headerView;
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(headerView);
        make.bottom.equalTo(headerView.mas_bottom).offset(-10);
    }];
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(56);
        make.left.right.equalTo(self.view);
    }];
}
```

其中在haderView上添加一个UISearchBar，后面又对headerView添加了约束。
这样在iOS 11之前没有问题，但是在iOS 12上确实会产生崩溃。


这个问题的解决方案有两种,

* 第一种就是不用Autolayout对headerView添加约束:

```
- (void)addHeaderView
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 56)];
    [headerView addSubview:self.searchBar];
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(headerView);
        make.bottom.equalTo(headerView.mas_bottom).offset(-10);
    }];
    self.orgFilterTable.tableHeaderView = headerView;
}
```

* 第二种还是使用autolayout来对headerView进行约束：

```
@interface MyViewController
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) MASConstraint *headerWidthConstraint;
@end

@implementation MyViewController

- (void)addHeaderView
{
    if (!self.headerView) {
        self.headerView = [[UIView alloc] init];
    }

    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.headerWidthConstraint = make.width.mas_equalTo(0);
        make.height.mas_equalTo(56);
    }];

    [self.headerView addSubview:self.searchBar];
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.headerView);
        make.bottom.equalTo(self.headerView.mas_bottom).offset(-10);
    }];
    self.orgFilterTable.tableHeaderView = self.headerView;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.headerWidthConstraint.offset = CGRectGetWidth(self.view.bounds);
    self.orgFilterTable.tableHeaderView = self.headerView;
}


@end

```