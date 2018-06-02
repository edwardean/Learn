# UIImagePickController打开闪光模式拍照瞬间锁屏crash

* 复现步骤：
 在UIImagePickController拍照页面开启闪光模式，在拍照的瞬间点击锁屏按钮，App重回前台后拍出来的照片一片漆黑，这时点击”使用照片”会crash。
 
 
* 原因：NSMutableDictionary setObject是参数传nil导致的。

  注意：当UIImagePickController的allowEditing属性为YES的时候不会crash。
  
* 解决方案：hook底层拍照处理API，当发现拍出来的照片为空时手动生成一张空白图片。

 通过Hopper查看产生这个问题有两处可能返回nil的调用，
 
 * 1. `-[PLPhotoTileViewController _newOriginalImageForPickerFromCachedData];` OC方法
 
 ```
 void * -[PLPhotoTileViewController _newOriginalImageForPickerFromCachedData](void * self, void * _cmd) {
    	rbx = self;
    	rax = [self unscaledImage];
    	if (rax == 0x0) {
            	rax = [rbx image];
    	}
    	rax = _NewUIImageFromCachedImage(rax);
    	return rax;
}
 ```
 
 * 2. `int _CreateImageDataFromJPEGDataAndOrientation(int arg0, int arg1);` C函数
 
 ```
	int _CreateImageDataFromJPEGDataAndOrientation(int arg0, int arg1) {
     	rbx = PLExifOrientationFromImageOrientation(arg1, arg1);
    	r15 = [NSDictionary alloc];
    	rdx = [NSNumber numberWithInt:rbx];
    	rbx = [r15 initWithObjectsAndKeys:rdx];
    	r14 = CGImageCreateEXIFJPEGData(0x0, arg0, 0x0, rbx);
    	[rbx release];
    	rax = r14;
    	return rax;
}
 ```
 
我们利用fishhook来对C函数进行hook。

* Code:

```
#import <fishhook/fishhook.h>
#import <objc/runtime.h>

#if __has_feature(objc_arc)
#error This file must be compiled with MRC. Use -fno-objc-arc flag (or convert project to MRC).
#endif

typedef id (*ImageDataIMP)(id, SEL, ...);

static CGImageRef (*orig_createImageData)(NSData *data, UIImageOrientation orientation);
UIImage *createBlankImage();

CGImageRef new_createImageData(NSData *arg0, UIImageOrientation arg1)
{
    CGImageRef imageRef = orig_createImageData(arg0, arg1);
    if (imageRef == NULL) {
        UIImage *image = createBlankImage();
        imageRef = CGImageRetain(image.CGImage);
        [image release];
    }
    return imageRef;
}


NSString *originCreateImageDataFromJPEGDataAndOrientationFuncKey()
{
    //CreateImageDataFromJPEGDataAndOrientation
    static NSString *key;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        key = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char [])
                                              {0x43, 0x72, 0x65, 0x61, 0x74, 0x65, 0x49, 0x6d, 0x61, 0x67, 0x65, 0x44, 0x61, 0x74, 0x61, 0x46, 0x72, 0x6f, 0x6d, 0x4a, 0x50, 0x45, 0x47, 0x44, 0x61, 0x74, 0x61, 0x41, 0x6e, 0x64, 0x4f, 0x72, 0x69, 0x65, 0x6e, 0x74, 0x61, 0x74, 0x69, 0x6f, 0x6e} length:41]
                                    encoding:NSASCIIStringEncoding];
    });
    return key;
}

NSString *originalImageForPickerFromCachedDataSELKey()
{
    //_newOriginalImageForPickerFromCachedData
    static NSString *key;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        key = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char [])
                                              {0x5f, 0x6e, 0x65, 0x77, 0x4f, 0x72, 0x69, 0x67, 0x69, 0x6e, 0x61, 0x6c, 0x49, 0x6d, 0x61,
                                                  0x67, 0x65, 0x46, 0x6f, 0x72, 0x50, 0x69, 0x63, 0x6b, 0x65, 0x72, 0x46, 0x72, 0x6f,
                                                  0x6d, 0x43, 0x61, 0x63, 0x68, 0x65, 0x64, 0x44, 0x61, 0x74, 0x61} length:40]
                                    encoding:NSASCIIStringEncoding];
    });
    return key;
}

@implementation UIImagePickerController (DEFImagePickerControllerCrashFix)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //先手动加载私有framework，否则取不到私有类
        NSBundle *photoLibraryBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/PhotoLibrary.framework"];
        if (![photoLibraryBundle load]) {
            return;
        }
        
        //PLPhotoTileViewController
        NSString *photoTileControllerKey = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char [])
                                                                           {0x50, 0x4c, 0x50, 0x68, 0x6f, 0x74, 0x6f, 0x54, 0x69,
                                                                               0x6c, 0x65, 0x56, 0x69, 0x65, 0x77, 0x43, 0x6f, 0x6e, 0x74,
                                                                               0x72, 0x6f, 0x6c, 0x6c, 0x65, 0x72} length:25] encoding:NSASCIIStringEncoding];
        
        Class originCls = NSClassFromString(photoTileControllerKey);
        [photoTileControllerKey release];
        Class overridedCls = self;
        
        SEL originalSelector = NSSelectorFromString(originalImageForPickerFromCachedDataSELKey());
        SEL overrideSelector = @selector(p_newOriginalImageForPickerFromCachedData);
        
        Method originalMethod = class_getInstanceMethod(originCls, originalSelector);
        Method overrideMethod = class_getInstanceMethod(overridedCls, overrideSelector);
        
        BOOL success = class_addMethod(originCls, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod));
        if (success) {
            class_replaceMethod(overridedCls, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, overrideMethod);
        }
        
        rebind_symbols((struct rebinding[1]){originCreateImageDataFromJPEGDataAndOrientationFuncKey().UTF8String, new_createImageData, (void *)&orig_createImageData}, 1);
    });
}

- (id)p_newOriginalImageForPickerFromCachedData
{
    SEL originalSelector = @selector(p_newOriginalImageForPickerFromCachedData);
    Method method = class_getInstanceMethod([UIImagePickerController class], originalSelector);
    ImageDataIMP imp = (ImageDataIMP)method_getImplementation(method);
    UIImage *image = imp(self, _cmd);
    if (!image) {
        //如果没有生成照片，返回一张空白图片，防止crash
        image = createBlankImage();
    }
    return image;
}

@end

//生成一张黑色图片
UIImage *createBlankImage()
{
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:[[UIScreen mainScreen] bounds]];
    UIImage *blackImage = [UIImage p_imageWithColor:[UIColor blackColor] path:bezierPath];
    CGImageRef imageRef = blackImage.CGImage;
    UIImage *drawImage = [[UIImage alloc] initWithCGImage:imageRef
                                                    scale:[UIScreen mainScreen].scale
                                              orientation:UIImageOrientationUp];
    return drawImage;
}

@interface UIImage (PickerBlankImage)
+ (UIImage *)p_imageWithColor:(UIColor *)color path:(UIBezierPath *)path;
@end

@implementation UIImage (PickerBlankImage)

+ (UIImage *)p_imageWithColor:(UIColor *)color path:(UIBezierPath *)path
{
    CGRect rect = CGRectMake(0, 0, 3, 3);
    if (path) {
        rect = path.bounds;
    }
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    if (path) {
        [path fill];
    } else {
        CGContextFillRect(context, rect);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
```