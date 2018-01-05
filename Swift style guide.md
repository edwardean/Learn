# Swift 编码规范
---

首先请阅读[苹果API设计指南](https://swift.org/documentation/api-design-guidelines)。

1. 代码格式
---

* 1.1 使用4个空格来缩进。
* 1.2 不要在一行中超过160个字符（在Xcode->Preferences->Text Editing->Page guide at cloumn中设置成160）
* 1.3 确保在每个文件中的末尾留出一行空行
* 1.4 确保在任何地方都没有尾随空白（勾选Xcode->Preferences->Text Editing->Automatically trim trailing whitespace + Including whitespace-only lines）
* 1.5 不要在新的一行开始写大括号

 ``` swift
 class SomeClass {
    func someMethod() {
        if x == y {
            /* ... */
        } else if x == z {
            /* ... */
        } else {
            /* ... */
        }
    }

    /* ... */
}
```
* 1.6 在写诸如属性，常量，变量，字典的key，方法参数，协议声明，或者父类时，不要在冒号前添加空格

``` swift
// specifying type
let pirateViewController: PirateViewController

// dictionary syntax (note that we left-align as opposed to aligning colons)
let ninjaDictionary: [String: AnyObject] = [
    "fightLikeDairyFarmer": false,
    "disgusting": true
]

// 声明一个方法
func myFunction<T, U: SomeProtocol>(firstArgument: U, secondArgument: T) where T.RelatedType == U {
    /* ... */
}

// 调用一个方法
someFunction(someArgument: "Kitten")

// 基类
class PirateViewController: UIViewController {
    /* ... */
}

// 协议
extension PirateViewController: UITableViewDataSource {
    /* ... */
}
```

* 1.7 通常情况下，逗号后面应该跟一个空格

``` swift
let myArray = [1, 2, 3, 4, 5]
```

* 1.8 在一些二元运算符诸如`+`, `==`或者`->`的前后应该有一个空格。
  在`(`后面和`)`前面不要有空格。
  
``` swift
let myValue = 20 + (30 / 2) * 3
if 1 + 1 == 3 {
    fatalError("The universe is broken.")
}
func pancake(with syrup: Syrup) -> Pancake {
    /* ... */
}
```
* 1.9 我们遵循Xcode推荐的缩进样式（比如在按下CTRL-L后就不应该再改动你的代码）。当我们声明一个函数跨越多行代码时，推荐使用Xcode默认的语法缩进方式。

``` swift
// Xcode为一个跨越多行代码的方法声明进行的缩进
func myFunctionWithManyParameters(parameterOne: String,
                                  parameterTwo: String,
                                  parameterThree: String) {
    print("\(parameterOne) \(parameterTwo) \(parameterThree)")
}

// Xcode对一个多行的`if`语句进行缩进
if myFirstValue > (mySecondValue + myThirdValue)
    && myFourthValue == .someEnumValue {

    print("Hello, World!")
}
```
* 1.10 当调用一个函数有很多参数时，将每个参数单独放在一行并且加上额外的缩进。

``` swift
someFunctionWithManyArguments(
    firstArgument: "Hello, I am a string",
    secondArgument: resultFromSomeFunction(),
    thirdArgument: someOtherLocalProperty)
```

* 1.11 当在处理一个很大的隐式数组或字典能够分割到多行的时候，就像在方法体中一样看待`[`和`]`，`if`语句，等等。方法中的闭包也应该同样对待。

``` swift
 someFunctionWithABunchOfArguments(
    someStringArgument: "hello I am a string",
    someArrayArgument: [
        "dadada daaaa daaaa dadada daaaa daaaa dadada daaaa daaaa",
        "string one is crazy - what is it thinking?"
    ],
    someDictionaryArgument: [
        "dictionary key 1": "some value 1, but also some more text here",
        "dictionary key 2": "some value 2"
    ],
    someClosure: { parameter1 in
        print(parameter1)
    })
```

* 1.12 首选使用局部常量或其他分解技术来尽可能的避免使用多行谓词。

```swift
// 推荐
let firstCondition = x == firstReallyReallyLongPredicateFunction()
let secondCondition = y == secondReallyReallyLongPredicateFunction()
let thirdCondition = z == thirdReallyReallyLongPredicateFunction()
if firstCondition && secondCondition && thirdCondition {
    // do something
}

// 不推荐
if x == firstReallyReallyLongPredicateFunction()
    && y == secondReallyReallyLongPredicateFunction()
    && z == thirdReallyReallyLongPredicateFunction() {
    // do something
}
```

2. 命名
---

* 2.1 在Swift中没有必要使用OC类型的前缀（比如直接用`GuybrushThreepwood `替代`LIGuybrushThreepwood `）。
* 2.2 用帕斯卡拼写法(大骆驼拼写法)来给类型命名（比如`struct`, `enum`, `class`, `typedef`, `associatedtype`,等等）。
* 2.3 用骆驼拼写法（首字母小写）来给函数，方法，属性，常量，变量，参数名，枚举case等等来命名。
* 2.4 当在处理首字母大写或者其他全部大写的名称时，实际上在代码中使用这个全部大写的名称。有一个例外就是当这个单词是在一个变量名称的开头时需要全部小写 - 在这种情况下，首字母缩写需要全部使用小写。

``` swift
// "HTML"在一个常量名的开头，所以我们使用小写的"html"
let htmlBodyContent: String = "<p>Hello, World!</p>"

// 使用ID取代Id
let profileID: Int = 1

// 使用URLFinder取代UrlFinder
class URLFinder {
    /* ... */
}
```
* 2.5 所有的实例独立常量除了单例以外都应该是`static`的。所有诸如`static`的常量都应该放在`enum`类型容器中（见**3.1.16**）。这个容器命名应该是单数（比如`Constant`,而不是`Constants`）并且它的命名应该相对明显能够明显看出是一个常量容器。如果命名不够明显，你可以在名称前添加`Constant`前缀。你可以用这些容器来组织一些相似或者有相同前缀，后缀或者相同用处的常量。

``` swift
class MyClassName {
    // 推荐
    enum AccessibilityIdentifier {
        static let pirateButton = "pirate_button"
    }
    enum SillyMathConstant {
        static let indianaPi = 3
    }
    static let shared = MyClassName()

    // 不推荐
    static let kPirateButtonAccessibilityIdentifier = "pirate_button"
    enum SillyMath {
        static let indianaPi = 3
    }
    enum Singleton {
        static let shared = MyClassName()
    }
}
```

* 2.6 对于泛型和关联类型，使用帕斯卡拼写法(大骆驼拼写法)单词来描述。如果这个单词和它遵循的一个协议冲突，或者和它的父类和子类冲突的话，你可以给这个关联类型或者泛型加上`Type`后缀。

``` swift
class SomeClass<Model> { /* ... */ }
protocol Modelable {
    associatedtype Model
}
protocol Sequence {
    associatedtype IteratorType: Iterator
}
```

* 2.7 名称应该具有描述性并且不能有歧义。

``` swift
// 推荐
class RoundAnimatingButton: UIButton { /* ... */ }

// 不推荐
class CustomButton: UIButton { /* ... */ }
```

* 2.8 不要用缩写，使用短名称或者一个单独的大写字母作为名称。

``` swift
// PREFERRED
class RoundAnimatingButton: UIButton {
    let animationDuration: NSTimeInterval

    func startAnimating() {
        let firstSubview = subviews.first
    }

}

// NOT PREFERRED
class RoundAnimating: UIButton {
    let aniDur: NSTimeInterval

    func srtAnmating() {
        let v = subviews.first
    }
}
```
* 2.9 在常量中或者变量名不够明显时包含类型信息。

``` swift
// 推荐
class ConnectionTableViewCell: UITableViewCell {
    let personImageView: UIImageView

    let animationDuration: TimeInterval

    // it is ok not to include string in the ivar name here because it's obvious
    // that it's a string from the property name
    let firstName: String

    // though not preferred, it is OK to use `Controller` instead of `ViewController`
    let popupController: UIViewController
    let popupViewController: UIViewController

    // when working with a subclass of `UIViewController` such as a table view
    // controller, collection view controller, split view controller, etc.,
    // fully indicate the type in the name.
    let popupTableViewController: UITableViewController

    // when working with outlets, make sure to specify the outlet type in the
    // property name.
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!

}

// 不推荐
class ConnectionTableViewCell: UITableViewCell {
    // this isn't a `UIImage`, so shouldn't be called image
    // use personImageView instead
    let personImage: UIImageView

    // this isn't a `String`, so it should be `textLabel`
    let text: UILabel

    // `animation` is not clearly a time interval
    // use `animationDuration` or `animationTimeInterval` instead
    let animation: TimeInterval

    // this is not obviously a `String`
    // use `transitionText` or `transitionString` instead
    let transition: String

    // this is a view controller - not a view
    let popupView: UIViewController

    // as mentioned previously, we don't want to use abbreviations, so don't use
    // `VC` instead of `ViewController`
    let popupVC: UIViewController

    // even though this is still technically a `UIViewController`, this property
    // should indicate that we are working with a *Table* View Controller
    let popupViewController: UITableViewController

    // for the sake of consistency, we should put the type name at the end of the
    // property name and not at the start
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var buttonSubmit: UIButton!

    // we should always have a type in the property name when dealing with outlets
    // for example, here, we should have `firstNameLabel` instead
    @IBOutlet weak var firstName: UILabel!
}
```
* 2.10 当在命名方法参数时，确保该方法能够易读并且能够明白每个参数的意图。
* 2.11 按照[苹果API设计指南](https://swift.org/documentation/api-design-guidelines/)，一个`protocol`当被描述为正在做某事的时候（比如`Collection`）应该被命名为名词,当它来描述某种能力（比如`Equatable`,`ProgressReporting `）时应该使用`able`,`ible`或者`ing`作为后缀。如果这些都不能都表达清晰的话，你还可以在protocol名字后加上`Protocol`后缀。下面是一些`Protocol`的例子。

``` swift
// here, the name is a noun that describes what the protocol does
protocol TableViewSectionProvider {
    func rowHeight(at row: Int) -> CGFloat
    var numberOfRows: Int { get }
    /* ... */
}

// here, the protocol is a capability, and we name it appropriately
protocol Loggable {
    func logCurrentState()
    /* ... */
}

// suppose we have an `InputTextView` class, but we also want a protocol
// to generalize some of the functionality - it might be appropriate to
// use the `Protocol` suffix here
protocol InputTextViewProtocol {
    func sendTrackingEvent()
    func inputText() -> String
    /* ... */
}
```

3. 代码风格
---

**3.1 一般情况**

* 3.1.1 尽可能使用`let`而不是`var`。
* 3.1.2 在迭代一个集合转换到另一个集合的时候应该使用`map`,`filter`,`reduce`等等。在使用这些方法时确保避免使用闭包，使用这些方法时使用闭包会有副作用。

``` swift
// 推荐
let stringOfInts = [1, 2, 3].flatMap { String($0) }
// ["1", "2", "3"]

// 不推荐
var stringOfInts: [String] = []
for integer in [1, 2, 3] {
    stringOfInts.append(String(integer))
}

// 推荐
let evenNumbers = [4, 8, 15, 16, 23, 42].filter { $0 % 2 == 0 }
// [4, 8, 16, 42]

// 不推荐
var evenNumbers: [Int] = []
for integer in [4, 8, 15, 16, 23, 42] {
    if integer % 2 == 0 {
        evenNumbers.append(integer)
    }
}
```
* 3.1.3 在编译器能够推断出类型的时候不要给常量或变量声明类型。
* 3.1.4 如果一个方法有多个返回值，使用`inout`参数返回一个元组（在你的返回值不够清晰时为了清晰起见最好使用标签元组）。如果某个元组使用超过一次，考虑用`typealias`。如果元组中返回值超过3个，考虑用`struct`或者`class`来代替。

``` swift
func pirateName() -> (firstName: String, lastName: String) {
    return ("Guybrush", "Threepwood")
}

let name = pirateName()
let firstName = name.firstName
let lastName = name.lastName
```
* 3.1.5 当在你的类中创建delegate和protocol属性时要保持警惕，通常，这些属性应该被声明成weak。
* 3.1.6 在逃逸闭包中直接访问`self`时要小心这样可能会产生循环引用，这种情况下应该使用[捕获列表](https://developer.apple.com/library/ios/documentation/swift/conceptual/Swift_Programming_Language/Closures.html#//apple_ref/doc/uid/TP40014097-CH11-XID_163)：

``` swift
// 推荐
myFunctionWithEscapingClosure() { [weak self] (error) -> Void in
    // you can do this

    self?.doSomething()

    // or you can do this

    guard let strongSelf = self else {
        return
    }

    strongSelf.doSomething()
}

// 不推荐
myFunctionWithEscapingClosure() { [weak self] (error) -> Void in
    //这是个编译器bug
    
    guard let `self` = self else { return }
    
    self.doSomething()
}
```

* 3.1.7 不要使用标签break

``` swift
func testBreak() {
    let a = false, b = true, x = 10, y = 20, err = true
    var errorFlagged = false
    nestedIf: if !a {
        if b && x > 0 {
            if y < 100 {
                if err {
                    errorFlagged = true
                    break nestedIf
                }
                // some statements
            } else {
                // other stuff
            }
        }
    }

    // skip handling if no error flagged.
    if errorFlagged {
        print("error")
        // handle error
    }
}
```
* 3.1.8 条件判断不要加括号

``` swift
// 推荐
if x == y {
    /* ... */
}

// 不推荐
if (x == y) {
    /* ... */
}
```
* 3.1.9 在使用枚举值时尽可能使用简写

``` swift
// 推荐
imageView.setImageWithURL(url, type: .person)

// 不推荐
imageView.setImageWithURL(url, type: AsyncImageView.Type.person)
```

* 3.1.10 类方法不要使用简写，一般从上下文中推断类方法要比枚举困难得多

``` swift
// 推荐
imageView.backgroundColor = UIColor.white

// 不推荐
imageView.backgroundColor = .white
```
* 3.1.11 除非有需要，一般不要写`self.`
* 3.1.12 在写方法时，要想一下这个方法是否要被重写。如果不是的话，将其标记为`final`，但是请记住这样会阻止方法在测试时被重写。通常，`final`方法会提升编译时间，这种情况下很使用。
* 3.1.13 当在使用诸如`else`,`catch`这类语句后面跟随有代码块的时候，将这些关键字跟代码块放在同一行。

``` swift
if someBoolean {
    // do something
} else {
    // do something else
}

do {
    let fileContents = try readFile("filename.txt")
} catch {
    print(error)
}
```

* 3.1.14 当在声明一个与类相关联的方法或属性而不是类的实例时最好使用`static`而不是`class`。当只有你需要重写这个方法或者属性会在子类中使用时才用`class`关键字，虽然可以考虑用`procotol`来这么做。
* 3.1.15 如果一个方法没有参数，没有副作用，并且返回某个对象或者某个值，考虑用一个计算属性来替代它。
* 3.1.16 如果在一个Swift文件中出现多次`Selector`，考虑将这些`Selector`抽离出来放到一个`Selector`的扩展中

``` swift
private extension Selector {
    struct ContactDetail {
        static let edit    = #selector(DEFContactDetailViewController.editActionHandler)
        static let discard = #selector(DEFContactDetailViewController.discardActionHandler)
        static let reuse   = #selector(DEFContactDetailViewController.reuseActionHandler)
    }
}

//用的时候这样
private let editBarButtonItem = UIBarButtonItem(title: "修改", style: .plain, target: self, action: Selector.ContactDetail.edit)

private let discardBarButtonItem = UIBarButtonItem(title: "废弃", style: .plain, target: self, action: Selector.ContactDetail.discard)

private let reuseBarButtonItem = UIBarButtonItem(title: "恢复", style: .plain, target: self, action: Selector.ContactDetail.reuse)
```
* 3.1.17 `deinit`方法要写到`init`前面或者类的开头部分，这样别人阅读代码中一眼就能看见你在`deinit`中做了什么或者漏掉了什么

3.2 访问修饰符
---

* 3.2.1 访问修饰符写在前面, 如果有`@objc`关键字的话，访问修饰符写在`@objc`后面

``` swift
// 推荐
private static let myPrivateNumber: Int
@objc private static let myPrivateNumber: Int

// 不推荐
static private let myPrivateNumber: Int
```
* 3.2.2 访问修饰符不要另起一行

``` swift
// 推荐
open class Pirate {
    /* ... */
}

// 不推荐
open
class Pirate {
    /* ... */
}
```

* 3.2.3 `internal`关键字是默认的，一般情况下不需要单独写出来
* 3.2.4 可能的话用`private`而不是`fileprivate`
* 3.2.5 如果属性对外是只读的，可以用`private(set)`来修饰

3.3 Switch语句和枚举
---

* 3.3.1 当使用的`switch`语句中的`case`条件是有限个数时，不要包含`default` case。
  应该将没有用到的case放在最后并且加上`break`关键字来阻止其执行。
* 3.3.2 `switch`语句中`default`分支如果不需要的话不要包含`break`关键字。
* 3.3.3 `switch`语句中的`case`语句应该按照默认顺序排列好。
* 3.3.4 当定义一个有关联值的`case`时，确保给关联值一个变量名成而不仅仅只有类型（比如`case hunger(hungerLevel: Int)`而不是`case hunger(Int)`）

``` swift
enum Problem {
    case attitude
    case hair
    case hunger(hungerLevel: Int)
}

func handleProblem(problem: Problem) {
    switch problem {
    case .attitude:
        print("At least I don't have a hair problem.")
    case .hair:
        print("Your barber didn't know when to stop.")
    case .hunger(let hungerLevel):
        print("The hunger level is \(hungerLevel).")
    }
}
```
* 3.3.5 可能的话用`fallthrough`关键字来取代case条件列表（比如`case 1, 2, 3:`）
* 3.3.6 如果一个default分支不可能被执行到，最好是抛出一个错误或者用其他类似的方式比如断言。

``` swift
func handleDigit(_ digit: Int) throws {
    switch digit {
    case 0, 1, 2, 3, 4, 5, 6, 7, 8, 9:
        print("Yes, \(digit) is a digit!")
    default:
        throw Error(message: "The given number was not a digit.")
    }
}
```

3.4 可选值
---
* 3.4.1 唯一有可能应该使用隐式可选值解包的情形是`@IBOutlet`。在其他的每个场景中，最好使用一个非可选值或者一个常规的可选值属性。是的，很多情形下你可以保证那些属性永远不可能为nil，但是这最好是安全并且一致的。类似的，不要使用强制解包。
* 3.4.2 不要使用`as!`或者`try!`。
* 3.4.3 如果你不打算使用在可选值中存储的值，但是需要检查其是否为`nil`的话，显式的检查值是否是`nil`而不是用`if let`语法。

``` swift
// 推荐
if someOptional != nil {
    // do something
}

// 不推荐
if let _ = someOptional {
    // do something
}
```
* 3.4.4 不要用`unowned`。你可以认为`unowned`在隐式解包时和`weak`属性有些类似（虽然`unowned `会完全无视引用计数会带来一些轻微的性能提升）。因为我们永远不想要隐式解包，同样不想要`unowned `属性。

``` swift
// 推荐
weak var parentViewController: UIViewController?

// 不推荐
weak var parentViewController: UIViewController!
unowned var parentViewController: UIViewController
```
* 3.4.5 当在解包一个可选值时，使用跟解包前的常量或变量一样的名称

``` swift
guard let myValue = myValue else {
    return
}
```

3.5 协议
---
当在实现协议的时候，有很多方式来组织你的代码：

1. 使用`// MARK:`注释从你代码的其余部分来分离协议的实现。
2. 在同一个源码文件中在类或者结构体实现代码的外面使用`extension`来组织协议实现代码。

切记当在使用扩展时，扩展中的方法不能被子类重载，这样可能会让测试变得困难。如果这中场景很常用，最好用第一种方法来保持一致性。否则，使用方法2将关注点分离使代码变的更加整洁。

特别是使用方法2时，添加`// MARK:`语句会让Xcode的方法/属性/类的列表看起来更易读。

3.6 属性
---
* 3.6.1 如果标记一个只读的计算属性，提供的getter方法不用加上`get {}`

``` swift
var computedProperty: String {
    if someBool {
        return "I'm a mighty pirate!"
    }
    return "I'm selling these fine leather jackets."
}
```
* 3.6.2 当在使用`get {}`,`set {}`,`willSet`和`didSet`时，给这些代码块添加缩进
* 3.6.3 尽管你可以在`willSet`/`didSet`和`set`方法中为新值和旧值自定义名称，但是请使用默认提供的`newValue`/`oldValue`标识符

``` swift
var storedProperty: String = "I'm selling these fine leather jackets." {
    willSet {
        print("will set to \(newValue)")
    }
    didSet {
        print("did set from \(oldValue) to \(storedProperty)")
    }
}

var computedProperty: String  {
    get {
        if someBool {
            return "I'm a mighty pirate!"
        }
        return storedProperty
    }
    set {
        storedProperty = newValue
    }
}
```
* 3.6.4 你可以按下面这种方式来声明一个单例对象

```swift
class PirateManager {
    static let shared = PirateManager()

    /* ... */
}
```

3.7 闭包
---

* 3.7.1 如果参数类型很明显，省略类型名称也无所谓，但是明确指定出类型名也是OK的。

``` swift
// 省略类型
doSomethingWithClosure() { response in
    print(response)
}

// 显式指定类型
doSomethingWithClosure() { response: NSURLResponse in
    print(response)
}

// 在map语句中使用$0隐含参数
[1, 2, 3].flatMap { String($0) }
```
* 3.7.2 如果将闭包指定成一个类型，除非有需要否则不要将闭包放在括号里（比如这个闭包是可选的或者这个闭包在另一个闭包里面）。要把参数放在一组括号里--用`()`来表明闭包没有参数，用`Void`来表明闭包没有返回值。

``` swift
let completionBlock: (Bool) -> Void = { (success) in
    print("Success? \(success)")
}

let completionBlock: () -> Void = {
    print("Completed!")
}

let completionBlock: (() -> Void)? = nil
```
* 3.7.3 尽可能将闭包的参数与闭包的左大括号放在同一行，除非太长超过了160个字符。
* 3.7.4 除非闭包的意义不是很明显或者闭包没有参数，否则就使用尾随闭包

``` swift
// 尾闭包
doSomething(1.0) { (parameter1) in
    print("Parameter 1 is \(parameter1)")
}

// 没有尾闭包
doSomething(1.0, success: { (parameter1) in
    print("Success with \(parameter1)")
}, failure: { (parameter1) in
    print("Failure with \(parameter1)")
})
```
3.8 数组
---
* 3.8.1 一般情况下要避免通过下标的方式访问数组元素。如果可能的话，用`.first`或者`.last`来访问，这样是可选的并且不会崩溃。尽可能使用`for item in items`而不是`for i in 0 ..< items.count`来遍历数组。如果你需要直接用下标来访问数组元素的话，确保做了边界检查。如果遍历数组时想要获取到index和元素，可以用`for (index, value) in items.enumerated()`的遍历方式。
* 3.8.2 永远不要用`+=`和`+`来追加和连接数组。应该用`.append()`或者`.append(contentsOf:)`。因为这些在当前的Swift状态下会更有效（至少对编译来说更有效）。
如果你基于另外一些数组生成一个不可变数组的话，用`let myNewArray = [arr1, arr2].joined()`来替代`let myNewArray = arr1 + arr2`。
* 3.8.3 如果想要在遍历数组中使用break语句的话，不要用`items.forEach { i in }`的方式来遍历，在forEach中的break不会跳出当前循环。

``` swift
//不要这样做
items.forEach { i in 
  if i > 10 {
    break
  }
}
```

3.9 错误处理
---
假设一个叫`myFunction`的方法返回一个`String`，然而在某个时刻它可能会发生错误。一个常见做法是让这个方法返回一个可选值`String?`,当错误发生时返回`nil`。
举例：

``` swift
func readFile(named filename: String) -> String? {
    guard let file = openFile(named: filename) else {
        return nil
    }

    let fileContents = file.read()
    file.close()
    return fileContents
}

func printSomeFile() {
    let filename = "somefile.txt"
    guard let fileContents = readFile(named: filename) else {
        print("Unable to open file \(filename).")
        return
    }
    print(fileContents)
}
```
我们应该用Swift中的`try`/`catch`来获取失败原因。

你可以用类似下面的结构体：

``` swift
struct Error: Swift.Error {
    public let file: StaticString
    public let function: StaticString
    public let line: UInt
    public let message: String

    public init(message: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        self.file = file
        self.function = function
        self.line = line
        self.message = message
    }
}
```
使用举例：

``` swift
func readFile(named filename: String) throws -> String {
    guard let file = openFile(named: filename) else {
        throw Error(message: "Unable to open file named \(filename).")
    }

    let fileContents = file.read()
    file.close()
    return fileContents
}

func printSomeFile() {
    do {
        let fileContents = try readFile(named: filename)
        print(fileContents)
    } catch {
        print(error)
    }
}
```
有一些例外情况使用可选值比错误处理更能够清晰表达意图。当结果在语义上可能为`nil`而不是在检索结果时出现错误时，使用可选值比使用错误处理会更清晰。

通常情况下，如果一个函数可能"失败"，并且返回一个可选类型并不能使错误原因表达清晰，这时抛出一个错误会更合适。

3.10 使用`guard`语句
---

* 3.10.1 一般来说，我们在`if`语句中更倾向于"提前返回"而不是用嵌套条件。这种情况用`guard`语句会让代码变得更加易读。

``` swift
// 推荐
func eatDoughnut(at index: Int) {
    guard index >= 0 && index < doughnuts.count else {
        // return early because the index is out of bounds
        return
    }

    let doughnut = doughnuts[index]
    eat(doughnut)
}

// 不推荐
func eatDoughnut(at index: Int) {
    if index >= 0 && index < doughnuts.count {
        let doughnut = doughnuts[index]
        eat(doughnut)
    }
}
```

* 3.10.2 当在解包可选值的时候，应该使用`guard`语句而不是用`if`来减少代码的缩进量。

``` swift
// 推荐
guard let monkeyIsland = monkeyIsland else {
    return
}
bookVacation(on: monkeyIsland)
bragAboutVacation(at: monkeyIsland)

// 不推荐
if let monkeyIsland = monkeyIsland {
    bookVacation(on: monkeyIsland)
    bragAboutVacation(at: monkeyIsland)
}

// 更不推荐
if monkeyIsland == nil {
    return
}
bookVacation(on: monkeyIsland!)
bragAboutVacation(at: monkeyIsland!)
```
* 3.10.3 在决定使用`if`还是`guard`语句时并不一定设计可选值解包,请记住最重要的事情就是为了提升代码的可读性。这里有不少这样的例子，比如判断两个不同的bool值，一个复杂的逻辑语句涉及到很多的比较条件等等。所以一般说来，你写代码时最好的判断标准就是保持代码的可读性和一致性。假如你对于`guard`和`if`哪个更易读或者这两个易读性差不多时，优先使用`guard`。

``` swift
// an `if` statement is readable here
if operationFailed {
    return
}

// a `guard` statement is readable here
guard isSuccessful else {
    return
}

// double negative logic like this can get hard to read - i.e. don't do this
guard !operationFailed else {
    return
}
```

* 3.10.4 假如是在两种状态之间作选择，使用`if`语句会比`guard`表达的更清晰。

``` swift
// 推荐
if isFriendly {
    print("Hello, nice to meet you!")
} else {
    print("You have the manners of a beggar.")
}

// 不推荐
guard isFriendly else {
    print("You have the manners of a beggar.")
    return
}

print("Hello, nice to meet you!")
```

* 3.10.5 只有当前的结果失败要离开当前上下文的时候才使用`guard`。下面有个例子说明使用两个`if`语句会比用两个`guard`要好 - 我们有两个不相关的条件并且不能互相干扰。

``` swift
if let monkeyIsland = monkeyIsland {
    bookVacation(onIsland: monkeyIsland)
}

if let woodchuck = woodchuck, canChuckWood(woodchuck) {
    woodchuck.chuckWood()
}
```

* 3.10.6 通常，有种情况是当我们需要解包多个可选值的时候使用`guard`语句。将多个解包操作放在一个单独的`guard`语句中跟将每个可选值单独解包是一样的。

``` swift
// combined because we just return
guard let thingOne = thingOne,
    let thingTwo = thingTwo,
    let thingThree = thingThree else {
    return
}

// separate statements because we handle a specific error in each case
guard let thingOne = thingOne else {
    throw Error(message: "Unwrapping thingOne failed.")
}

guard let thingTwo = thingTwo else {
    throw Error(message: "Unwrapping thingTwo failed.")
}

guard let thingThree = thingThree else {
    throw Error(message: "Unwrapping thingThree failed.")
}
```

* 3.10.7 当`guard`中`else`里的代码只有一行时可以将整个`guard`语句放在同一行中。否则应该折行。

``` swift
guard let thingOne = thingOne else { return }

guard let thingOne = thingOne else { 
	fatalError()
	return
}
```