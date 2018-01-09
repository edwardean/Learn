## 解决Carthage导致的编译时copy-framework命令的阻塞问题

现象：

由于我们的iOS项目中集成了Carthage，根据Carthage配置，需要在项目的Build Phase中添加`copy-frameworks`命令将framework拷贝到ipa中

![屏幕快照 2017-10-20 下午6.25.08.png](http://upload-images.jianshu.io/upload_images/10432-2c87ca514e101c5c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这个`copy-frameworks`命令由于未知原因在编译项目时会出现很大几率卡在这个命令上，拖慢编译时间，由于没有研究`copy-frameworks`源码所以该问题出现的原因具体未深入调查。

后来了解了这个命令做的事情，大概可分成这几步：

1. 根据项目中当前的Valid Architectures, 从framework中剔除不需要（也就是不包含在Valid Architectures中）的架构
2. 重新签名剔除不需要架构的framework
3. 将framework拷贝到编译product目录中

所以根据上述步骤，可以本地写一份python代码来完成上述几个步骤，代码如下：

``` python

import os
import subprocess
import re
import shutil

def main():
    
    valid_architectures = set(os.environ["VALID_ARCHS"].split(" "))
    input_file_count = int(os.environ["SCRIPT_INPUT_FILE_COUNT"])
    input_files = [os.environ["SCRIPT_INPUT_FILE_{}".format(index)] for index in range(0, input_file_count )]
    expanded_identity = os.environ["EXPANDED_CODE_SIGN_IDENTITY"]
    built_products_dir = os.environ["BUILT_PRODUCTS_DIR"]
    frameworks_folder_path = os.environ["FRAMEWORKS_FOLDER_PATH"]
    frameworks_path = os.path.join(built_products_dir, frameworks_folder_path)
    code_signing_allowed = os.environ["CODE_SIGNING_ALLOWED"] == "YES"
    
    for input_path in input_files:
        # We don't modify the input frameworks but rather the ones in the built products directory
        output_path = os.path.join(frameworks_path, os.path.split(input_path)[1])
        
        framework_name = os.path.splitext(os.path.split(input_path)[1])[0]
        
        print "# Frameworks Path: {}".format(frameworks_path)
        print "# Copying framework {}".format(framework_name)
        print "# input_path: {}, output_path: {}".format(input_path, output_path)

        if os.path.exists(output_path):
            shutil.rmtree(output_path)

        shutil.copytree(input_path, output_path)
        
        framework_path = output_path
        
        if not code_signing_allowed:
            continue
    
        binary_path = os.path.join(framework_path, framework_name)
        
        
        # Find out what architectures the framework has
        output = subprocess.check_output(["/usr/bin/xcrun", "lipo", "-info", binary_path])
        match = re.match(r"^Architectures in the fat file: (.+) are: (.+)".format(binary_path), output)
        assert(match.groups()[0] == binary_path)
        architectures = set(match.groups()[1].strip().split(" "))
        
        # Produce a list of architectures that are not valid
        excluded_architectures = architectures.difference(valid_architectures)
        
        # Skip if all architectures are valid
        if not excluded_architectures:
            continue

        # For each invalid architecture strip it from framework
        for architecture in excluded_architectures:
            print "# Stripping {} from {}".format(architecture, framework_name)
            output = subprocess.check_output(["/usr/bin/xcrun", "lipo", "-remove", architecture, "-output", binary_path, binary_path])
            print output

# Resign framework
        print "# Resigning {} with {}".format(framework_name, expanded_identity)
        result = subprocess.check_call(["/usr/bin/xcrun", "codesign", "--force", "--sign", expanded_identity, "--preserve-metadata=identifier,entitlements", binary_path])

if __name__ == "__main__":
    main()

```

下面的事情就是把原来在Build Phase中执行的Carthage命令换成执行上面这个python脚本就好了：

![屏幕快照 2017-10-20 下午6.35.07.png](http://upload-images.jianshu.io/upload_images/10432-75a81e14f795f2e9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

经过这样一番改进后，Carthage命令烦人的卡死现象再也没有了 :)
