## Swift脚本之自动更新Xcode工程BundleVersion

Swift作为一种全能语言，除了能写客户端之外其实还能用来写Server甚至还能用来写脚本的。更新Xcode工程的BudleVersion这件事情python和shell脚本都能做，并且跟Xcode的兼容性也不错。但作为iOS开发来说尝试一下用Swift来做这件事听起来也比较合乎情理了。

下面上一段Swift代码：

``` swift
import Foundation

private typealias taskData = (pipe: Pipe, task: Process)

public func updateBundleVersion(_ plistPath: String) {


    print("plistPath: \(plistPath)")

    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: plistPath) else {
        print("⚠️  请输入Info.plist文件路径")
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

//获取命令行参数
let arguments = CommandLine.arguments

print("⚠️  arguments: \(arguments)")

if arguments.count >= 2 {
    let infoPlistFile = arguments[1]
    updateBundleVersion(infoPlistFile)
} else {
    print("❗️  缺少Info.plist路径输入参数！")
}

```

这段Swift代码无法直接在Xcode中运行，可以在命令行中调用,
比如把这段代码保存为`updateBundleVersion.swift`:

``` shell
swift updateBundleVersion.swift ./Info.plist
```

我尝试了一下按这种方式放在Xcode 的Build Phases中调用的话会报错:

![1512714581081-image.png](http://upload-images.jianshu.io/upload_images/10432-c3396d4f5f6a0f89.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

后来在网上有人将Swift源码放到Build Phases中来直接调用

![1512716641796-image.png](http://upload-images.jianshu.io/upload_images/10432-04fad9126e3cfa22.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

虽然这样开起来比较丑，但毕竟算是在Swift脚本之路上迈出了坚实的一步了。