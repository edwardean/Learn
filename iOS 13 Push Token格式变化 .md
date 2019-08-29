## iOS 12以前：
APNS Token:

```
<1af53094 5dd5102a 6420681f a7220ddb 5cf51468 36b53ed1 9238ed98 ede8a69b>
```

PushKit Token:

```
<02f56952 4c28b341 90cd5919 956d7742 18560e54 aaf16af8 7f3d0233 ea7c4f3b>
```

## iOS 13:
APNS Token:

```
{length = 32, bytes = 0xe84aee36 f3b44c5b bf2f30fa 7dd70e17 ... b86d6ed7 1cb76296 }
```

PushKit Token:

```
{length = 32, bytes = 0x1cd7193e 807b5e80 91c78793 a87acf77 ... a683fbca e5fdde81 }
```

## iOS 13后Token正确的解析方案探寻
|  方案 | 代码 | 真机设备iOS 13系统解析结果输出| 真机设备iOS 12系统解析结果输出 |
| :-------- | :----------------- | -------------| ------------- |
| 线上老的Token解析方案  | ![carbon.png-w150](https://upload-images.jianshu.io/upload_images/10432-b9a8132566cd1293.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)  |  `Origin PKPush token: {length = 32, bytes = 0x1cd7193e 807b5e80 91c78793 a87acf77 ... a683fbca e5fdde81 }` <br> `线上解析方案： PKPush token: %7Blength=32,bytes=0x1cd7193e807b5e8091c78793a87acf77...a683fbcae5fdde81%7D` | `Origin PKPush token: <02f56952 4c28b341 90cd5919 956d7742 18560e54 aaf16af8 7f3d0233 ea7c4f3b>`  <br> `线上解析方案： PKPush token: 02f569524c28b34190cd5919956d774218560e54aaf16af87f3d0233ea7c4f3b` |
|  方案一  |  ![carbon2.png](https://upload-images.jianshu.io/upload_images/10432-959c0b2849e5bbe5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240) | `解析方案一：PKPush token: 1cd7193e807b5e8091c78793a87acf77d870bbc420479328a683fbcae5fdde81` | `解析方案一：PKPush token: 02f569524c28b34190cd5919956d774218560e54aaf16af87f3d0233ea7c4f3b` |
| 方案二 | ![carbon3.png](https://upload-images.jianshu.io/upload_images/10432-f98dba00023a11e8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240) | `解析方案二：PKPush token: 1cd7193e807b5e8091c78793a87acf77d870bbc420479328a683fbcae5fdde81` |  `解析方案二：PKPush token: 02f569524c28b34190cd5919956d774218560e54aaf16af87f3d0233ea7c4f3b`


* 线上解析方案代码:

```
NSString *token = [NSString stringWithFormat:@"%@", pushCredentials.token];
KDBLog(@"Origin PKPush token: %@", token);
    
token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
token = [token stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
NSLog(@"线上解析方案： PKPush token: %@", token);
```

* 方案一代码：

```
NSData *tokenData = pushCredentials.token;
if (tokenData.length >= 8) {
    const unsigned *tokenBytes = (const unsigned *)[tokenData bytes];
    token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
             ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
             ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
             ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    NSLog(@"解析方案一：PKPush token: %@", token);
}
```

* 方案一代码：

```
NSMutableString *deviceTokenString = [NSMutableString string];
const char *bytes = pushCredentials.token.bytes;
NSInteger count = pushCredentials.token.length;
for (int i = 0; i < count; i++) {
    [deviceTokenString appendFormat:@"%02x", bytes[i]&0x000000FF];
}
NSLog(@"解析方案二：PKPush token: %@", deviceTokenString);
```

## 结论：iOS 13系统上除了线上老的解析方案外，方案一和方案二均能正常解析token。并且方案一和方案二还能兼容iOS13以前的系统Token格式。

> 参考：
> [https://forums.developer.apple.com/thread/117545](https://forums.developer.apple.com/thread/117545 "https://forums.developer.apple.com/thread/117545")

>  [https://info.umeng.com/detail?id=174&&cateId=1](https://info.umeng.com/detail?id=174&&cateId=1 "https://info.umeng.com/detail?id=174&&cateId=1")
