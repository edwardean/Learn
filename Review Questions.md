
* `NSNotification`是同步还是异步

* `UIButton`的继承链

* `MD5`和`Base64`都是用来做什么的，区别是什么？

* `isKindOfClass`和`isMemberOfClass`的区别

* 什么是 KVC 和 KVO？KVC 查找方法的顺序？什么时候系统会调用 `valueForUndefinedKey`？

* `NSMapTable`,`NSDictionary`,`NSCache`的异同，`NSHashTable`和`NSArray`的异同?

* 简述`__bridge_retained`，`__bridge_transfer`，`__bridge`的区别和各自的使用场景？

* 简述一下利用`dispatch_source`实现定时器功能的实现方式。

* NSProxy的基类是什么？它是用来做什么的？

* `NSURLProtocol`用来干什么？

* `__block`关键字在MRC和ARC下的含义一样吗？
* OC中可以向已经编译好的类中添加实例变量吗？
* 在子线程中新建`NSTimer`能正常工作吗？
* `dispatch_after`是延迟添加到队列中还是添加延迟执行？
* 如果暂停动画再开始

* 设计一个能够显示屏幕刷新率的工具类

* 调用一个block块对象之前要对该对象先判空，否则会crash，为什么会crash，crash时的内存地址是0xc，背后的原理是什么

* `strlen([@"💩" UTF8String])` 和 `[@"💩" length]`算出来的值相等吗？

* `UIView`和`CALayer`的关系？
* OC中对`nil`对象发消息的返回值是多少？ 
* `NSDateFormatter`是线程安全吗，使用的正确姿势是？
* 怎样统计项目中未使用的类？
* 如何自己实现抓crash的工具，发生crash时不让app崩溃怎么做？
* 算法打印0～100以内的质数


* 下面代码输出结果

``` objc
- (void)viewDidLoad {
    [super viewDidLoad];

    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"1");
        }];
        
        [[NSOperationQueue currentQueue] addOperationWithBlock:^{
            NSLog(@"2");
        }];
        
        __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"MyNotif" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSLog(@"Receive Notification");
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }];
        
        [[NSOperationQueue currentQueue] addOperationWithBlock:^{
            NSLog(@"3");
        }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MyNotif" object:self];
        
        [[NSOperationQueue currentQueue] addOperationWithBlock:^{
            NSLog(@"4");
        }];
    });

```
* 下面这段代码能正常运行吗？存在几处问题？

``` objc
	SEL selector = @selector(viewWillAppear:);

	NSInvocation *invocation = [NSInvocation 	invocationWithMethodSignature:selector];
	invocation.target = target;
	invocation.selector = selector;
	BOOL animated = YES;
	[invocation setArgument:&animated atIndex:0];
	[invocation invoke];

	id returnValue = nil;
	[invocation getReturnValue:& returnValue];
	NSLog(@"%@", returnValue);
```

* 下面代码块的能正常运行吗？为什么？

``` objc
UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
dispatch_async(dispatch_get_main_queue(), ^{
     [webView stringByEvaluatingJavaScriptFromString:@"alert(hello)"];
 });
```

* 下面代码块运行结果是什么？为什么？

``` objc
	- (BOOL)doSomethingWithError:(NSError **)error {
    __block BOOL success = YES;
    [@[@1] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            success = NO;
            if (error) {
                *error = [NSError errorWithDomain:@"com.custom.error" code:-1 userInfo:nil];
            }
        }
    }];
    
    return success;
}
/////////////////////////
    NSError *error = nil;
    [self doSomethingWithError:&error];
    NSLog(@"%@", error);
```

* 下面两段代码分别输出什么结果？
	
``` objc
### OC
  NSMutableArray *mutableArray = [NSMutableArray arrayWithObjects:@1,@2,@3,@4,nil];
    for (NSNumber *number in mutableArray) {
        NSLog(@"%@",number);
        if (number.unsignedIntegerValue == 1) {
            [mutableArray addObject:@5];
        }
    }
### Swift
   var mutableArray = [1,2,3,4]
   for number in mutableArray {
       print("\(number)")
         if number == 1 {
            mutableArray.append(5)
         }
    }
```
为什么OC的代码crash而Swift的没事?

* 下面的代码段运行结果是什么？

``` objc
+ (instancetype)sharedInstance {
    static LHDefaultManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        [[LHDefaultManager sharedInstance] callMe];
    });
    return _sharedInstance;
}

- (void)callMe {
  NSLog(@"callMe");
}
```
* 下面代码段中三次输出都是什么内容？

``` objc
@interface ViewController: UIViewController
@property (nonatomic, strong) NSString *strongString;
@property (nonatomic, assign) NSString *assignString;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //Quiz 1
    self.strongString = [NSString stringWithFormat:@"string"];
    self.assignString = self.strongString;
    self.strongString = nil;
    NSLog(@"assignString = %@", self.assignString);
    
    //Quiz 2
    self.strongString = @"string1234";
    self.assignString = self.strongString;
    self.strongString = nil;
    NSLog(@"assignString = %@", self.assignString);
    
    //Quiz 3
    self.strongString = [[NSString alloc] initWithUTF8String:"string1234"];
    self.assignString = self.strongString;
    self.strongString = nil;
    NSLog(@"assignString = %@", self.assignString);
}

@end
```

* 讨论一下平时App常见的优化怎么做。

* 大数加法

```
+ (NSString *)largrNumberSum:(NSString *)n1 anotherNumber:(NSString *)n2 {
    NSInteger n1Length = n1.length;
    NSInteger n2Length = n2.length;
    NSInteger maxLength = MAX(n1Length, n2Length);
    
    // 对其位数，不够前面补0
    if (maxLength == n1Length) {
        // n2Length < n1Length
        for (NSInteger i = 0; i < n1Length - n2Length; i++) {
            n2 = [@"0" stringByAppendingString:n2];
        }
    } else {
        // n1Length < n2Length
        for (NSInteger i = 0; i < n2Length - n1Length; i++) {
            n1 = [@"0" stringByAppendingString:n1];
        }
    }
    
    NSString *sumString = @"";
    NSInteger carryBit = 0;
    for (NSInteger i = maxLength - 1; i >= 0; i--) {
        NSRange range = NSMakeRange(i, 1);
        NSInteger currentBitNumber1 = [n1 substringWithRange:range].integerValue;
        NSInteger currentBitNumber2 = [n2 substringWithRange:range].integerValue;
        
        NSInteger currentBitSum = currentBitNumber1 + currentBitNumber2 + carryBit;
        carryBit = currentBitSum > 9 ? 1 : 0;
        currentBitSum%=10;
        sumString = [[NSString stringWithFormat:@"%zd", currentBitSum] stringByAppendingString:sumString];
    }
    if (carryBit == 1) {
        sumString = [@"1" stringByAppendingString:sumString];
    }
    return sumString;
}
```