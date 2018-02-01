## Swift Pitfall
---

#### 在deinit中访问lazy成员

比如这是在一个叫`TestController`的类中

``` swift
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    deinit {
        tableView.delegate = nil
        tableView.dataSource = nil
    }
```
如果在某种情况下创建一个`TestController`的实例，但是没等`TestController`的view显示出来实例就被释放的话上面的代码就会crash。

``` swift
let controller = TestController()
controller = nil 
```
* 原因1： 是因为如果执行`deinit`时tableView是nil的话，`deinit`中的代码实际上相当于懒加载调用`tableView`的初始化方法，在初始化方法中设置了`delegate`和`dataSource`，之就相当于OC中在`dealloc`中访问`weak`的`self`一样会crash。
* 原因2：如果这时controller的view还没构造出来的话view属性这时还是nil，上面的
`let tableView = UITableView(frame: view.bounds, style: .plain)`这一行中访问了`view.bounds`，这就相当于对view属性做强制解包。可想而知对nil强制解包的后果，自然是crash。

#### OC中调用Swift方法

比如有一个Swift方法

``` Swift
    @objc func formatLocation(_ location: CLLocation) -> String {
       return "\(location.coordinate.latitude * 1e6)" + "," + "\(location.coordinate.longitude * 1e6)"
    }
```

在OC中调用时这样写

```
NSString *formattedLocation = [LocationManager formatLocation:nil];
```
这样调用会crash。
如果Swift中暴露给OC的方法的参数是非Optional的话，在OC中调用这个方法传nil的话编译器是没办法给你做类型检查的话，如果你恰好这么做了，那么等待你的只有crash。
所以这种情况下我推荐的一种安全做法就是:
> 如果不确定OC中调用该方法时参数会不会传空，定义方法参数时就定义成`Optional`类型，然后再方法体中利用`guard`来对参数作空值判断。
``` Swift
    @objc func formatLocation(_ location: CLLocation?) -> String {
       guard let location = location else { return "" } 
       return "\(location.coordinate.latitude * 1e6)" + "," + "\(location.coordinate.longitude * 1e6)"
    }
```

#### Swift 4 NSKeyValueObservation

这里有个复现该问题的[Demo](https://github.com/viki-org/swift4-kvo-crash-demo)

Demo中的代码确实会crash，并且只有iOS11以下的系统才有问题，crash原因至今不明
