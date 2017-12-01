## 一段keychain方法内存泄漏修复记录

先来看一段代码

``` objc 
NSMutableDictionary *attributeQuery = [query mutableCopy];
[attributeQuery setObject: (id) kCFBooleanTrue forKey:(__bridge_transfer id) kSecReturnAttributes];
CFTypeRef attrResult = NULL;
OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) attributeQuery, &attrResult);
```
这段代码在Leaks中在第四行会报内存泄漏，

![](https://i.loli.net/2017/12/01/5a21075ba0f0c.png)

一开始还以为是第一个参数中的`__bridge`问题，当把`__bridge`改成`__bridge_retained`之后内存泄漏报的更严重了。

分析：
首先这里用`__bridge`是没有问题的，此时`attributeQuery`的引用计数是1，而`__bridge`关键字并没有牵涉到内存管理权的转移，也就是说`attributeQuery`
的内存还是受ARC管理，等第四行代码运行之后`attributeQuery`可以正常收到`release`消息引用计数变为0内存被系统正常回收。那这里的问题到底出在哪呢？

这时候再仔细看后面第二个参数，传递的是一个地址，可以大胆的猜测SecItemCopyMatching内部实现中对的第二个参数指向的内存做了一次retain操作：

``` objc
OSStatus SecItemCopyMatching(CFDictionaryRef query, CFTypeRef * __nullable CF_RETURNS_RETAINED result) {
    ....
    if (result) {
        result = CFCreate(....); //retain here
    }
    ....
    return ....;
}
```

并且`SecItemCopyMatching`函数中也第二个参数前也明确有`CF_RETURNS_RETAINED`关键字，先来看看`CF_RETURNS_RETAINED`是什么:

``` objc
#ifndef CF_RETURNS_RETAINED
#if __has_feature(attribute_cf_returns_retained)
#define CF_RETURNS_RETAINED __attribute__((cf_returns_retained))
#else
#define CF_RETURNS_RETAINED
#endif
#endif
```

这里有关于[`CF_RETURNS_RETAINED`](https://clang-analyzer.llvm.org/annotations.html#attr_cf_returns_retained)的解释。

![](https://i.loli.net/2017/12/01/5a2106a91f5f7.png)

意思是说有`CF_RETURNS_RETAINED`标记的参数或者返回值它的调用发要负责对其作`release`操作。
说道这里结论已经很明显了，在这段代码中由于第二个参数使用后没有`release`导致内存泄漏。

正确的代码应该是这样：

``` objc
NSMutableDictionary *attributeQuery = [query mutableCopy];
[attributeQuery setObject: (id) kCFBooleanTrue forKey:(__bridge_transfer id) kSecReturnAttributes];
CFTypeRef attrResult = NULL;
OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) attributeQuery, &attrResult);

//after use attrResult ....
if (attrResult) {
    CFRelease(attrResult);
}
```

在`attrResult`使用完之后需要将其release才行。
