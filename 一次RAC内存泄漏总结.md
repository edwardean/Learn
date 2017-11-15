# 一次RAC内存泄漏问题总结

[ReactiveCocoa](http://www.github.com/ReactiveCocoa/ReactiveCocoa)在函数响应式编程方面给大家带来的便利就不用多说了吧。我们项目中大量运用了RAC配合MVVM模式。但是RAC本身虽然很强大，但是稍有不慎也会产生很多意想不到的问题，本文就从一次内存循环引用问题的查找来说一下在RAC使用过程当中需要注意哪些问题，避免不小心掉入内存循环引用的怪圈里去。

在每次项目提测阶段，我都有将项目代码过一遍Instruments的习惯，一来能够避免将一些未及时发现的深层次问题带到线上去，二来也能及时发现并解决问题，这样能够在团队中分享一下解决问题的经验。

我一般查内存循环引用都喜欢用Allocations模板，其实说到查找循环引用大家可能了解过一些已经存在的开源方案，比如[FBRetainCycleDetector](https://github.com/facebook/FBRetainCycleDetector),[HeapInspector](https://github.com/tapwork/HeapInspector-for-iOS)等等，我觉着引入这些工具后确实能够及时发现内存使用中存在的问题，但我觉着配置和使用维护起来毕竟还是要耗费一些精力，之前我使用过一些国人出品的一些工具但是发现其中内存误报率很大，所以在项目中并没有使用这些类似的工具。

还接着说用Allocations查找循环引用问题，打开Instruments中的Allocations模板，在其中过滤想要关注的内存对象名称，在页面之间切换的同时观察对象的Persistent只是不是只增不减，这样来判定该对象是否产生了循环引用。

1、选择Allocations模板

![](https://i.loli.net/2017/11/15/5a0c34178ebf0.png)

2、添加要过滤的关键字

![](https://i.loli.net/2017/11/15/5a0c343672a96.png)

在大概上个版本上线以前，我在用Allocations追踪内存循环引用时发现有一个在UICollectionViewCell上使用的model类在内存中占有的个数只增不减，在反复查看业务代码后并没有发现有循环引用的痕迹。更奇怪的是使用该model类的Controller和Cell在页面退出时内存占用都能正常的回收，下面是追踪该model类时的记录：

![](https://i.loli.net/2017/11/15/5a0c34466d839.png)

![](https://i.loli.net/2017/11/15/5a0c34587e30b.png)

![](https://i.loli.net/2017/11/15/5a0c3469591b6.png)

连续几次进入该页面。发现`DEFMerchantTagGroupModel`和`DEFMerchantTagModel`两个类的个数只增不减，查看它们产生的Stack Trace时都指向了一处viewModel中的代码：

![](https://i.loli.net/2017/11/15/5a0c3479e57d9.png)

viewModel中的逻辑是这样的：

``` objc
- (RACCommand *)tagCommand
{
    if (!_tagCommand) {
        _tagCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id params) {
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                [DDSharedAPIClient fetchListTagModels:params completion:^(NSDictionary *responseData, NSError *error) {
                    if (responseData) {
                        [subscriber sendNext:[DEFMerchantTagGroupModel objectArrayWithKeyValuesArray:responseData]];
                    } else if (error) {
                        [subscriber sendError:error];
                    } else {
                        [subscriber sendNext:nil];
                    }
                }];
                return nil;
            }];
        }];
    }
    return _tagCommand;
}
```
乍一看这块代码没什么问题，block中没有持有self，也就不会跟self产生引用闭环所以也就没有加weak strong的必要。明明只有这里产生了model对象并且在业务代码中并没有跟model发生引用循环的逻辑那为什么页面退出后model在内存中的个数还一直增加不减少呢？

到这里一度陷入了僵局，迟迟没有找到到底在哪里出了问题。

既然查model没有什么结论那就索性查查RAC中的对象在内存中的使用情况吧，
果然发现RAC中的对象也有只增不减的情况，

![](https://i.loli.net/2017/11/15/5a0c348b0d8ea.png)
发现`RACSubscriber`每次进入该页面返回后在Persistent中的数量也是一直增加，这是我才恍然想起来viewModel中的代码到底哪里出了问题，
因为`RACSubscriber`跟`subscriberWithNext:`后面的block是一种强持有关系，只有手动对`RACSubscriber`发`[subscriber sendCompleted]`消息时才会解除这对引用关系，正因为上面代码中缺少了`[subscriber sendCompleted]`的调用，才导致`RACSubscriber`和`subscriberWithNext:`的block连同block中生成的model对象一直都倔强的留在了内存中。


``` objc
+ (instancetype)subscriberWithNext:(void (^)(id x))next error:(void (^)(NSError *error))error completed:(void (^)(void))completed {
	RACSubscriber *subscriber = [[self alloc] init];

	subscriber->_next = [next copy];
	subscriber->_error = [error copy];
	subscriber->_completed = [completed copy];

	return subscriber;
}
```

``` objc
- (void)sendCompleted {
	@synchronized (self) {
		void (^completedBlock)(void) = [self.completed copy];
		[self.disposable dispose];

		if (completedBlock == nil) return;
		completedBlock();
	}
}
```
到这里真相已经浮出水面了，解决办法就是补充上缺少的`[subscriber sendCompleted];`方法；

---
上面这个问题只是RAC导致的循环引用中比较难以发现的一个，RAC产生的其他循环引用问题基本上都是跟持有它的业务类有关，下面我整理了一些其他常见的RAC循环引用的case，帮助大家借鉴和参考。

* RACCommand属性懒加载中没有weak strong

``` objc
- (RACCommand *)reloadCommand
{
    if (!_reloadCommand) {
        //@weakify(self);
        _reloadCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                //@strongify(self);
                [self reloadData];
                [subscriber sendNext:nil];
                return nil;
            }];
        }];
    }
    return _reloadCommand;
}
```

* RACObserve中没有weak strong

``` objc
 self.flattenMapSignal = [signal flattenMap:^RACStream *(DDModel *model) { 
        return RACObserve(model, title);
    }];
```
这个例子如果没有weak strong的话乍一看很难发现会有循环引用，其实问题都出在了
`RACObserve`这个宏上。这个宏是这样的：

``` objc
#define RACObserve(TARGET, KEYPATH) \
    ({ \
        __weak id target_ = (TARGET); \
        [target_ rac_valuesForKeyPath:@keypath(TARGET, KEYPATH) observer:self]; \
    })
```
将这个宏展开到上面的代码块中是这样的：

``` objc
 self.flattenMapSignal = [signal flattenMap:^RACStream *(DDModel *model) {
        __weak GJModel *target_ = model;
        return [target_ rac_valuesForKeyPath:@keypath(target_, title) observer:self];
    }];
```
宏展开后明显能够看到block里持有了self，而block又通过flattenMapSignal属性被self持有，这样便形成一个了引用闭环。

* RACCommand实例对象的subscribeNext中没有weak strong

``` objc
    [self.merchantDataViewModel.fetchIndicatorDetails.errors subscribeNext:^(id x) {
        self.merchantDataViewModel.indicatorDetail = self.merchantDataViewModel.errorIndicatorDetail;
    }];
```

* block属性中显式或隐式引用self没有weak strong

``` objc
//vc.m
                [menu showBelowRect:self->_filterBar.frame
                             inView:self.view
                           animated:YES
                     selectionBlock:^(NSUInteger index) {
                         self.indexForStatus = index;
                     }
                  dismissBlock:^{
                }];
  
  
//menu.m
- (void)showBelowRect:(CGRect)rect
               inView:(UIView *)view
             animated:(BOOL)animated
       selectionBlock:(void(^)(NSUInteger index))selectionBlock
         dismissBlock:(void(^)())dismissBlock
{
    self.selectionBlock = selectionBlock;
    self.dismissBlock = dismissBlock;

    [view addSubview:self];
}
```
上例中menu调用的方法中selectionBlock中显式的引用的self，而后menu又add到self.view上面，这样便形成了一个引用闭环，不结合两个文件的代码来看很难发现

* tableViewCell的block中引用的VC

``` objc
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDCustomListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DEFVisitPlanListCell"];  
    if (indexPath.row <= self.listViewModel.visitPlanList.count) {       
        cell.operateButtonTapBlock = ^(UIButton *operateButton) {
            self.currentOperateView = operateButton;
        };
    }
    return cell;
}
```
上面的代码你能一眼看出问题在哪吗？
这个循环引用闭环上涉及的对象比较多，这个闭环是这样的cell->operateButtonTapBlock->self(VC)->self(VC).view->UITableView→cell

* Assert中隐式的持有self

首先Assert断言是一个宏，将其展开后是这样的：

``` objc
#define NSAssert(condition, desc, ...)  \
    do {                \
    __PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    if (__builtin_expect(!(condition), 0)) {        \
            NSString *__assert_file__ = [NSString stringWithUTF8String:__FILE__]; \
            __assert_file__ = __assert_file__ ? __assert_file__ : @"<Unknown File>"; \
        [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
        object:self file:__assert_file__ \
            lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
    }               \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
    } while(0)
```
好，知道了Assert其中会持有self了，那把第五条的代码稍微改两行再看一下问题出在哪

``` objc
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDCustomListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DEFVisitPlanListCell"];  
    if (indexPath.row <= self.listViewModel.visitPlanList.count) { 
        @weakify(self);      
        cell.operateButtonTapBlock = ^(UIButton *operateButton) {
            NSAssert(operateButton);
            @strongify(self);
            self.currentOperateView = operateButton;
        };
    }
    return cell;
}
```
这下能看出问题在哪了吧！

其实不只NSAssert有问题，NSParameterAssert一样也有问题，因为NSParameterAssert只是对NSAssert的封装

``` objc
#define NSParameterAssert(condition) NSAssert((condition), @"Invalid parameter not satisfying: %@", @#condition)
```
