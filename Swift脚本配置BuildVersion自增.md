# Swift脚本配置BuildVersion自增
---

### Background
我们项目中之前增加用Swift脚本在每次CI构建成功后自动上传dSYM文件到性能分析平台的功能，这样能保证在每次发生crash后，crash后台能够将crash信息同性能分析平台上相同的dSYM文件作符号化，这样就能把崩溃信息正确的呈现出来了。

但是我们的性能监测平台上来记录每个版本对应的dSYM符号表文件是通过版本号+BundleVersion来标记的，恰好我们项目的BundleVersion又是手动写死的，比如3.9.0版本的Build号就是390。
这样的话在每个版本开发和提测阶段上传的dSYM文件到性能分析平台后会产生新文件覆盖老文件的问题，那么就会导致之前安装的App发生崩溃后无法用最新的dYSM文件来符号化出来，看起来就像下面这样：

[![image2018-1-11 11_1_50.png](https://i.loli.net/2018/01/11/5a56dec12fc64.png)](https://i.loli.net/2018/01/11/5a56dec12fc64.png)

### How To Do
---
所以这种情况只有自动上传符号表还不够，还需要把每个符号表和每次CI构建的版本一一对应起来。那么怎么来做这件事呢，有一个思路就是可以用一个策略让每次CI构建的时候把项目的Build号发生变化。
最简单的就是在每次CI构建时获取当前git的commit次数，把这个commit数设置成工程的Build号，这样一来基本可以保证每次CI构建时Build号都是不相同的，并且还是增加的。进而能解决相同Build号的符号表文件被覆盖的问题。

### To Do
---

#### 1. 获取git当前分支的commit次数

```
git rev-list head | sort | wc -l
```

#### 2. 更新Info.plist文件中的Build号

```
/usr/libexec/PlistBuddy -c Set :CFBundleVersion $Build_Number $Info_plist_file
```

#### 3. 把前两部操作组合起来写一个Swift脚本文件

```
import Foundation
 
private typealias taskData = (pipe: Pipe, task: Process)
 
public func updateBundleVersion(_ plistPath: String) {
 
 
    print("plistPath: \(plistPath)")
 
    let fileManager = FileManager.default
 
    guard fileManager.fileExists(atPath: plistPath) else {
        print("❗️  请输入Info.plist文件路径")
        return
    }
     
    let taskTuple = shellPipe(launchPath: "/usr/bin/git", args: ["rev-list", "head"])
    let sortTask = shellPipe(launchPath: "/usr/bin/sort", inputTask: taskTuple)
    let commitNumberTask = shellPipe(launchPath: "/usr/bin/wc", inputTask: sortTask, args: ["-l"])
     
    guard let commitNumber = shell(task: commitNumberTask) else {
        return
    }
     
    print("commitNumber:\(commitNumber)")
     
    let updateBundleVersionTask = shellPipe(launchPath: "/usr/libexec/PlistBuddy",
                                            args: ["-c","Set :CFBundleVersion \(commitNumber)", "\(plistPath)"])
    shell(task: updateBundleVersionTask)
}
 
private func shellPipe(launchPath: String, inputTask: taskData? = nil, args: [String]? = nil) -> taskData {
    let task = Process()
    task.launchPath = launchPath
     
    var command = launchPath
     
    if let arguments = args {
        task.arguments = arguments
        command += arguments.flatMap{ $0 }.joined(separator: " ")
    }
    print("⚠️  Executing command: \(command)")
     
    if let inputTaskTuple = inputTask {
       task.standardInput = inputTaskTuple.pipe
    }
     
    let outPutPipe = Pipe()
    task.standardOutput = outPutPipe
     
    if let inputTaskTuple = inputTask {
        inputTaskTuple.task.launch()
    }
     
    return (outPutPipe, task)
}
 
@discardableResult
private func shell(task: taskData) -> String? {
    task.task.launch()
     
    let data = task.pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String? = String(data: data, encoding: .utf8)
     
    task.task.waitUntilExit()
     
    let status = task.task.terminationStatus
    if status == 0 {
        print("✅  Success")
    } else {
        print("❗️ Error: \(output ?? "")")
    }
     
    if let result = output {
        return result.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    } else {
        return nil
    }
}
 
let arguments = CommandLine.arguments
print("⚠️  arguments: \(arguments)")
 
if arguments.count >= 2 {
    let infoPlistFile = arguments[1]
    updateBundleVersion(infoPlistFile)
} else {
    print("❗️  缺少Info.plist路径输入参数！")
}
```

#### 4.在fastlane中新增一个lane action，在其中调用这个swift脚本文件
  增加一个`update_build_version`的lane action
  
  ``` ruby
  desc "Update BundleVersion"
lane :update_build_version do
    system("swift ../shell/updateBundleVersion.swift ../#{info_plist_path.shellescape}")
end
  ```
  
  注意`#{info_plist_path.shellescape}`这一句，`info_plist_path`本来指代的是Info.plist文件的路径，在我们项目中就是`"MOMA/Supporting Files/Info.plist"`，但是其中有个空格，这样的话`"MOMA/Supporting"`和`"Files/Info.plist"`会被当作两个字符串来处理，这样可以在后面增加`shellescape`来对空格进行转义处理。
  
#### 5. 在Fastfile的`before_all`中来调用上一步中的`update_build_version`命令

``` ruby
platform :ios do
  before_all do
    update_build_version
  end
end
```

### Rust
---
经过上面这几步之后我们可以先在本地测试一下执行结果了，在终端中执行

``` ruby
bundle exec fastlane update_build_version
```

会发现有类似下面这样的输出：

[![image2018-1-11 11_30_22.png](https://i.loli.net/2018/01/11/5a56e098a8f95.png)](https://i.loli.net/2018/01/11/5a56e098a8f95.png)

再看一看Info.plist文件中的Build号是不是已经被设置成3715了:

[![image2018-1-11 11_32_3.png](https://i.loli.net/2018/01/11/5a56e0c7368c8.png)](https://i.loli.net/2018/01/11/5a56e0c7368c8.png)

妥妥的，很成功~
