
![图片](https://i.niupic.com/images/2020/04/06/7i9N.jpeg)


**结论：**

1. 实例对象的isa指向对象所属的类, 也叫类对象；
2. 类对象的isa指向的是类对象所属的类，也就是元类对象；
3. 元类对象的isa指向根元类对象；
4. 根元类的isa指向本身。
5. 根元类对象superClass指向NSObject类对象


方法  | 代码
:------------- | :-------------
`+ isMemberOfClass`  | ```+ (BOOL)isMemberOfClass:(Class)cls { return object_getClass((id)self) == cls; }```
`- isMemberOfClass`|```- (BOOL)isMemberOfClass:(Class)cls { return [self class] == cls;}```
`+ isKindOfClass`|`+ (BOOL)isKindOfClass:(Class)cls { for (Class tcls = object_getClass((id)self); tcls; tcls = tcls->superclass) { if (tcls == cls) return YES; } return NO; }`
`- isKindOfClass`|`- (BOOL)isKindOfClass:(Class)cls { for (Class tcls = [self class]; tcls; tcls = tcls->superclass) { if (tcls == cls) return YES; }`
`+ (Class)class`|`+ (Class)class { return self; }`
`- (Class)class`|`- (Class)class {  return object_getClass(self); }`
`Class object_getClass(id obj);`|`Class object_getClass(id obj) { if (obj) return obj->getIsa(); else return Nil; }`

 **NSObject相关测验：**
 
```
BOOL a1 = [[NSObject new] isKindOfClass:[NSObject class]];  
```
> 
结果：YES
>  
NSObject对象的isa指向类对象，所以相等

```    
BOOL a2 = [[NSObject class] isKindOfClass:[NSObject class]];
```
>
结果：YES  
>
NSObject类对象发送isKindOfClass方法，相当于object_getClass([NSObject class]), 获取到NSObject的元类；
看+isKindOfClass方法实现：
第一次比较，NSObject元类和NSObject类对象不相等, 继续获取元类的superclass进行第二次比较
NSObject元类的的superclass指向NSObject类对象，相当于判断(NSObjct类对象) == (NSObjct类对象), 所以相等；

```
BOOL a3 = [[NSObject new] isMemberOfClass:[NSObject class]];
```
>
结果：YES  
>
根据-isMemberOfClass方法实现，左边实际获取的是[NSObject class]，也就是NSObject类对象，右边刚好就是NSObject类对象，所以相等；

```
BOOL a4 = [[NSObject class] isMemberOfClass:[NSObject class]];
```
>
结果：NO  
>
根据+ (BOOL)isMemberOfClass方法实现，左边object_getClass([NSObject class]), 相当于获取NSObject的元类对象，但是右边是NSObject类对象，两者不等；
  
    
**NSObject子类测验：**

```
@interface Foo : NSObject
@end
```
```
BOOL res1 = [[Foo class] isKindOfClass:[Foo class]];
```
>
结果：NO
>
根据+isKindOfClass的实现，左边相当于object_getClass([Foo class])，取到的是Foo的元类对象，
元类对象调用isKindOfClass与Foo类对象相比，不可能一样，所以结果是NO

```
BOOL res2 = [[Foo class] isKindOfClass:[[Foo class] class]];
```
>
结果：NO
>
左边还是Foo的元类对象；右边相当于对Foo发送两次class方法，但是+class方法只是返回自己，相当于右边取到的还是Foo对象；
后面就跟第一题其实一模一样，返回NO

```
BOOL res3 = [[Foo class] isKindOfClass:object_getClass([Foo class])];
```
>
结果：YES
>
左边跟上一题一样，获取Foo元类对象；右边这时获取的也是Foo的元类对象；故左右相等；

```
BOOL res4 = [[Foo class] isKindOfClass:object_getClass([NSObject class])];
```
>
结果：YES
>
这一题稍微绕一点；
左边是Foo的元类；右边获取的是NSObject的元类，也就是根元类；
根据最上面的图，Foo元类的isa其实就是指向了根元类，故左右相等，返回YES；

```
BOOL res5 = [[Foo class] isMemberOfClass:[Foo class]];
```
>
结果：NO
>
左边取到的是Foo的元类，右边是Foo类，两者不一样，该题返回NO;

```
BOOL res6 = [[Foo class] isMemberOfClass:[[Foo class] class]];
```
>
结果：NO
>
左边取到的是Foo的元类，右边同第2题一样，获取的仍然是Foo类；两者还是不一样，返回NO；

```
BOOL res7 = [[Foo class] isMemberOfClass:object_getClass([Foo class])];
```
>
结果: YES
>
左边是Foo的元类，右边也是Foo的元类，两者是同一对象；所以返回YES;

```
BOOL res8 = [[Foo class] isMemberOfClass:[NSObject class]];
```
>
结果: NO
>
左边是Foo的元类，右边是NSObject类对象，两者不一样；返回NO;
