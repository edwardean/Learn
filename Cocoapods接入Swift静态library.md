## Cocoapods接入Swift静态library

> Cocoapods从1.5.3版本开始起引入Swift静态库不再需要在Podfile中添加`use_frameworks!`了。源码引入Swift库代码后生成的Target将会是.a的形式。

![1542851770887-image.png](https://i.loli.net/2018/11/22/5bf61ee3b1547.png) 

![1542851945683-image.png](https://i.loli.net/2018/11/22/5bf61ef257ac2.png)


下面说一下具体的接入方式。

### 1.将Pod版本改为1.5.3或更高版本
如果是在Gemfile中指定的pod版本，可以这样修改：

```
gem 'cocoapods', '~> 1.5.3'
```

Pod版本改成1.5版本之后可能会遇到OC头文件引入报错的问题。比如有些OC库中引入AFNetworking的头文件这样写：

```
#import <AFNetworking.h>
```
那么在Pod 1.5.0之后版本就会报错：`file not found with angled include use quotes instead`, 其实严格头文件引入应该这样写：

```
#import <AFNetworking/AFNetworking.h>
```

这个错误怎样解决呢？可以在Podfile的post_install钩子中修改OC库的header search path, 添加自己依赖的pod的header路径

```
platform = OpenStruct.new(name: :ios)
public_headers = installer.sandbox.public_headers.search_paths(platform)
installer.pods_project.build_configurations.each do |config|
    config.build_settings['HEADER_SEARCH_PATHS'] = public_headers.join(' ')
end
```

### 2.在Podfile中添加我们需要引入的Swift Pod

```
pod 'DEFImageUploader', '0.1.0'
```

### 3.Pod install后在项目中使用Swift库

##### 3.1 在Swift中使用

* `import DEFImageUploader`

##### 3.2 在OC中使用
* `@import DEFImageUploader;`


### 在OC中引入Swift Pod库可能遇到的问题
在上面3.2中提到的是以Module的方式import需要使用的Swift库的。这个前提是Xcode工程的`Enable Module`必须是打开的。

##### 挑战1
但是我们项目中使用了[Ccache](https://pspdfkit.com/blog/2015/ccache-for-fun-and-profit/)这个工具来为项目编译加速。但是Ccache使用的前提是要把Xcode工程的`Enable Module`设置关闭。这样一来在OC中就无法使用`@import DEFImageUploader;`的方式来引入Swift库，要改为`#import <DEFImageUploader/DEFImageUploader-Swift.h>`的方式引入。

![1542856510974-image.png](https://i.loli.net/2018/11/22/5bf61f4c6083b.png)


##### 挑战2
我们使用`#import <DEFImageUploader/DEFImageUploader-Swift.h>`来引入头文件后报错，大意就说`DEFImageUploader-Swift.h`这个桥接头文件找不到，不论怎么修改引入方式，比如

```
#import <DEFImageUploader-Swift.h>
```

还有

```
#import "DEFImageUploader-Swift.h"
```
的引入方式都会报错。

其实`DEFImageUploader-Swift.h`桥接头文件已经生成了。
Cocoapods在`DEFImageUploader`的target的Build Phases中自动添加了一个`Copy generated compatibility header`的Script，将`DEFImageUploader-Swift.h`拷贝到了`${BUILT_PRODUCTS_DIR}/Swift Compatibility Header`路径下。

`Copy generated compatibility header`脚本内容如下

```
COMPATIBILITY_HEADER_PATH="${BUILT_PRODUCTS_DIR}/Swift Compatibility Header/${PRODUCT_MODULE_NAME}-Swift.h"
MODULE_MAP_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_MODULE_NAME}.modulemap"

ditto "${DERIVED_SOURCES_DIR}/${PRODUCT_MODULE_NAME}-Swift.h" "${COMPATIBILITY_HEADER_PATH}"
ditto "${PODS_ROOT}/Headers/Public/DEFImageUploader/DEFImageUploader.modulemap" "${MODULE_MAP_PATH}"
ditto "${PODS_ROOT}/Headers/Public/DEFImageUploader/DEFImageUploader-umbrella.h" "${BUILT_PRODUCTS_DIR}"
printf "\n\nmodule ${PRODUCT_MODULE_NAME}.Swift {\n  header \"${COMPATIBILITY_HEADER_PATH}\"\n  requires objc\n}\n" >> "${MODULE_MAP_PATH}"

```
但是`DEFImageUploader-Swift.h`头文件这么拷贝的路径是在`DerivedData`下，在Xcode项目中的Header Search Path中确是

```
"${PODS_ROOT}/Headers/Public"
```

这个路径展开就是在`项目根路径/Pods/Headers/Public`, 这个路径明显跟上面的`${BUILT_PRODUCTS_DIR}/Swift Compatibility Header`不一样，怪不得会找不到头文件报错。

既然问题已经发现了怎么解决呢？ 我的方法是在Podfile中添加一段脚本，让项目每次编译后将`DEFImageUploader-Swift.h`从原本的`DerivedData`路径拷贝到`项目根路径/Pods/Headers/Public/DEFImageUploader/`路径下。
这段脚本放在Podfile中的post_install钩子中，具体代码如下:

```
post_install do |installer|
  installer.pods_project.targets.each do |target|
        compatibilityPhase = target.build_phases.find { |ph| ph.display_name == 'Copy generated compatibility header' }
        if compatibilityPhase
            build_phase = target.new_shell_script_build_phase('Copy Swift Generated Header')
            build_phase.shell_script = <<-SH.strip_heredoc
                COMPATIBILITY_HEADER_PATH="${BUILT_PRODUCTS_DIR}/Swift Compatibility Header/${PRODUCT_MODULE_NAME}-Swift.h"
                ditto "${COMPATIBILITY_HEADER_PATH}" "${PODS_ROOT}/Headers/Public/${PRODUCT_MODULE_NAME}/${PRODUCT_MODULE_NAME}-Swift.h"
            SH
        end
  end
end
```

代码大意就是做拷贝`-Swift.h`桥接头文件的事情。

这个脚本会在Pod每次编译后执行，这样在项目代码中引入`#import <DEFImageUploader/DEFImageUploader-Swift.h>`就不会报错了。