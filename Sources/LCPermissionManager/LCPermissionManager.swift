//
//  LCPermissionManager.swift
//
//  Created by DevLiuSir on 2023/11/22.
//

import Cocoa


public class LCPermissionManager: NSObject {
    /// 单例
    public static let shared = LCPermissionManager()
    
    // MARK: - private
    
    /// 权限窗口控制器
    /// - 用于显示权限设置窗口
    private var permissionWC: LCPermissionWindowController?
    
    /// 权限类型数组
    /// - 保存当前需要检测或设置的权限类型
    private var authTypes: [LCPermissionModel] = []
    
    /// 权限状态监控定时器
    /// - 用于定时刷新和检测权限状态
    private var monitorTimer: Timer? = nil
    
    /// 是否已跳过权限设置
    /// - 标记用户是否选择跳过权限设置
    private var skipped: Bool = false
    
    private override init() {}
    
    
    
    /// 是否所有权限都已授权
    public var allAuthPassed: Bool {
        var flag = true
        for model in authTypes {
            switch model.authType {
            case .accessibility:
                flag = flag && LCPermissionManager.getPrivacyAccessibilityIsEnabled()
            case .screenCapture:
                flag = flag && LCPermissionManager.getScreenCaptureIsEnabled()
            case .fullDisk:
                flag = flag && LCPermissionManager.getFullDiskAccessIsEnabled()
            default:
                break
            }
            if flag == false { break }
        }
        return flag
    }
    
    /// 是否点击了跳过授权
    public var isSkipped: Bool {
        return skipped
    }
    
    /// 点击了跳过授权
    public var skipHandler: (() -> Void)?
    
    /// 点击了退出
    public var quitHandler: (() -> Void)?
    
    /// 所有权限都已授权后的回调
    /// - 当所有权限都已开启时调用
    public var allAuthPassedHandler: (() -> Void)?
    
    /// 教学视频链接，不设置则不显示 观看权限设置教学>> 的按钮
    public var tutorialLink: String = ""
    
    // MARK: - 循环监听
    
    /// 一次性监听所有权限，如果有权限未授权，则会显示授权窗口，当所有权限都授权时，则自动隐藏
    /// - Parameters:
    ///   - authTypes: 需要授权的权限
    ///   - repeatSeconds: * 3 为 定时监听的秒数（比如，传入5s，则15s内检测3次，3次都返回false，则弹出授权窗口），一旦某个权限有变化，就会更新显示；默认为0，表示不重复，授权完毕后，退出监测
    private var second = 0 // 记录过了多少秒
    private var retryCount = 0 // 如果获取到有权限未授权，重新获取，超过一定次数，则判断为未全部授权，防止系统问题引起的授权窗口弹出
    
    
    // MARK: - 定时监听权限
    public func monitorPermissionAuthTypes(_ authTypes: [LCPermissionModel], repeat repeatSeconds: Int = 0) {
        self.authTypes = authTypes
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            if repeatSeconds <= 0 {
                // 不需要循环检测
                if self.allAuthPassed {
                    self.monitorTimer?.invalidate()
                    self.monitorTimer = nil
                    if self.permissionWC != nil {
                        self.passAuth()
                    }
                    return
                }
                // 有权限未授权，弹出授权窗口
                if self.permissionWC == nil {
                    self.permissionWC = LCPermissionWindowController()
                    self.permissionWC?.permissionVC.allAuthPassedHandler = {
                        // 已全部授权
                        self.monitorTimer?.invalidate()
                        self.monitorTimer = nil
                        self.passAuth()
                    }
                    self.permissionWC?.permissionVC.skipHandler = {
                        // 跳过
                        self.skipAuth()
                    }
                    self.permissionWC?.permissionVC.quitHandler = {
                        // 退出
                        self.quitHandler?()
                    }
                    self.permissionWC?.closeHandler = {
                        // 点击了关闭按钮
                        self.monitorTimer?.invalidate()
                        self.monitorTimer = nil
                        self.permissionWC = nil
                    }
                    self.permissionWC?.permissionVC.authTypes = authTypes
                } else {
                    self.permissionWC?.permissionVC.refreshAllAuthState()
                }
                self.permissionWC?.window?.orderFrontRegardless()
            } else {
                self.second += 1
                if self.second >= repeatSeconds {
                    // 达到了设置的间隔秒数
                    self.second = 0
                    if self.allAuthPassed == false {
                        self.retryCount += 1
                        if self.retryCount < 3 {
                            return
                        }
                        self.retryCount = 0
                        // 有权限未授权，弹出授权窗口
                        if self.permissionWC == nil {
                            self.permissionWC = LCPermissionWindowController()
                            self.permissionWC?.permissionVC.allAuthPassedHandler = {
                                // 已全部授权
                                self.passAuth()
                            }
                            self.permissionWC?.permissionVC.skipHandler = {
                                // 跳过
                                self.skipAuth()
                            }
                            self.permissionWC?.permissionVC.quitHandler = {
                                // 退出
                                self.quitHandler?()
                            }
                            self.permissionWC?.permissionVC.authTypes = authTypes
                        }
                        self.permissionWC?.window?.orderFrontRegardless()
                    } else {
                        // 都已授权
                        if self.permissionWC != nil {
                            self.passAuth()
                        }
                    }
                } else if self.permissionWC != nil {
                    // 如果授权窗口在，每秒刷新一次状态
                    self.permissionWC?.permissionVC.refreshAllAuthState()
                }
            }
        })
    }
    
    
    // MARK: - 一次性监听
    
    // MARK: 检查多个权限是否同时开启
    public func checkPermissionAuth(_ authTypes: [LCPermissionAuthType]) -> Bool {
        var flag = true
        for type in authTypes {
            switch type {
            case .accessibility:
                flag = flag && LCPermissionManager.getPrivacyAccessibilityIsEnabled()
            case .screenCapture:
                flag = flag && LCPermissionManager.getScreenCaptureIsEnabled()
            case .fullDisk:
                flag = flag && LCPermissionManager.getFullDiskAccessIsEnabled()
            default:
                break
            }
            if flag == false {
                break
            }
        }
        return flag
    }
    
    // MARK: 显示授权窗口
    public func showPermissionAuth(_ authTypes: [LCPermissionModel]) {
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            if self.permissionWC == nil {
                self.permissionWC = LCPermissionWindowController()
                self.permissionWC?.permissionVC.allAuthPassedHandler = {
                    // 已全部授权
                    self.monitorTimer?.invalidate()
                    self.monitorTimer = nil
                    self.passAuth()
                }
                self.permissionWC?.permissionVC.skipHandler = {
                    // 跳过
                    self.skipAuth()
                }
                self.permissionWC?.permissionVC.quitHandler = {
                    // 退出
                    self.quitHandler?()
                }
                self.permissionWC?.closeHandler = {
                    // 点击了关闭按钮
                    self.monitorTimer?.invalidate()
                    self.monitorTimer = nil
                    self.permissionWC = nil
                }
                self.permissionWC?.permissionVC.authTypes = authTypes
            } else {
                self.permissionWC?.permissionVC.refreshAllAuthState()
            }
            self.permissionWC?.window?.orderFrontRegardless()
        })
    }
    
    
    // MARK: 通过授权
    private func passAuth() {
        permissionWC?.close()
        permissionWC = nil
        allAuthPassedHandler?()
    }
    
    // MARK: 跳过授权
    private func skipAuth() {
        permissionWC?.close()
        permissionWC = nil
        monitorTimer?.invalidate()
        monitorTimer = nil
        skipped = true
        skipHandler?()
    }
    
    // MARK: 检查某个权限是否开启，如果未开启，则弹出Alert，请求打开权限
    @discardableResult
    public static func checkPermission(authType type: LCPermissionAuthType) -> Bool {
        var flag = true
        var selector: Selector?
        var tips: String = ""
        switch type {
        case .accessibility:
            flag = getPrivacyAccessibilityIsEnabled()
            tips = "Accessibility Tips"
            selector = #selector(openPrivacyAccessibilitySetting)
        case .screenCapture:
            flag = getScreenCaptureIsEnabled()
            tips = "ScreenCapture Tips"
            selector = #selector(openScreenCaptureSetting)
        case .fullDisk:
            flag = getFullDiskAccessIsEnabled()
            tips = "Full disk access Tips"
            selector = #selector(openFullDiskAccessSetting)
        default:
            break
        }
        
        // 未授权，弹窗
        if flag == false {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = LCPermissionManager.localizeString("Kind tips")
            alert.informativeText = String(format: LCPermissionManager.localizeString(tips), LCPermissionManager.appName)
            alert.addButton(withTitle: LCPermissionManager.localizeString("To Authorize"))
            alert.addButton(withTitle: LCPermissionManager.localizeString("Cancel"))
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let sel = selector, responds(to: sel)  {
                    perform(sel)
                }
            }
        }
        return flag
    }
    
    
    
    // MARK: 获取辅助功能权限状态
    public static func getPrivacyAccessibilityIsEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
    
    // MARK: 获取录屏权限是否打开
    public static func getScreenCaptureIsEnabled() -> Bool {
        guard #available(macOS 10.15, *) else { return true }
        let currentPid = NSRunningApplication.current.processIdentifier
        // 获取当前屏幕上的窗口信息
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[CFString: Any]] else { return false }
        for dict in windowList {
            if let name = dict[kCGWindowName] as? String,
               !name.isEmpty,
               let pid = dict[kCGWindowOwnerPID] as? pid_t,
               pid != currentPid,
               let runningApp = NSRunningApplication(processIdentifier: pid),
               let execName = runningApp.executableURL?.lastPathComponent,
               execName != "Dock" {
                return true
            }
        }
        return false
    }
    
    // MARK: 获取完全磁盘权限是否打开
    public static func getFullDiskAccessIsEnabled() -> Bool {
        if #available(macOS 10.14, *) {
            let isSandbox = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
            let userHomePath: String
            
            if isSandbox {
                guard let pw = getpwuid(getuid()), let homeDir = pw.pointee.pw_dir else {
                    fatalError("Failed to retrieve home directory in sandbox mode.")
                }
                userHomePath = String(cString: homeDir)
            } else {
                userHomePath = NSHomeDirectory()
            }
            
            let testFiles = [
                "\(userHomePath)/Library/Safari/CloudTabs.db",
                "\(userHomePath)/Library/Safari/Bookmarks.plist",
                "/Library/Application Support/com.apple.TCC/TCC.db",
                "/Library/Preferences/com.apple.TimeMachine.plist"
            ]
            
            for file in testFiles {
                let fd = open(file, O_RDONLY)
                if fd != -1 {
                    close(fd)
                    return true
                }
            }
            return false
        }
        return true
    }
    
    // MARK: 打开辅助功能权限设置窗口
    @objc public func openPrivacyAccessibilitySetting() {
        // 构造辅助功能权限设置的 URL
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        NSWorkspace.shared.open(URL(string: url)!)
        
        // 模拟键盘事件，将app带入到权限列表
        guard let eventRef = CGEvent(source: nil) else { return }
        let point = eventRef.location
        guard let mouseEventRef = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else { return }
        mouseEventRef.post(tap: .cghidEventTap)
    }
    
    // MARK: 打开录屏权限设置窗口
    @objc public func openScreenCaptureSetting() {
        /// 检查系统版本是否支持
        if #available(macOS 10.15, *) {
            if #available(macOS 11.0, *) {
                /// 请求屏幕录制权限
                CGRequestScreenCaptureAccess()
            } else {
                /// macOS 10.15 没有 CGRequestScreenCaptureAccess，因此采取截屏以提示用户授予屏幕录制权限
                let _ = CGWindowListCreateImage(CGRect(x: 0, y: 0, width: 1, height: 1), .optionOnScreenOnly, kCGNullWindowID, [])
                /// 不需要释放截屏，Swift 会自动处理内存管理
            }
            DispatchQueue.main.async {
                /// 异步在主队列中打开系统偏好设置以授予屏幕录制权限
                let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
                NSWorkspace.shared.open(URL(string: urlString)!)
            }
        }
    }
    
    
    
    // MARK: 打开完全磁盘权限设置窗口
    @objc public func openFullDiskAccessSetting() {
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        NSWorkspace.shared.open(URL(string: url)!)
    }
    
    
    
    // MARK: - 本地化相关
    
    /// 获取当前类所在的 Bundle（通常用于从资源包中加载本地化文件、图片等资源）
    ///
    /// 适用于将 `LCPermissionManager` 作为模块（如 Swift Package 或 CocoaPods）集成时，
    /// 确保资源可以正确加载，而不是从主 Bundle 中查找。
    static let bundle = Bundle(for: LCPermissionManager.self)
    
    
    
    /// 获取本地化字符串（从 LCPermissionManager.bundle 中的 LCPermissionManager.strings 文件）
    ///
    /// - Parameter key: 本地化键值（通常是英文原文）
    /// - Returns: 对应的本地化字符串，如果未找到则返回空字符串
    static func localizeString(_ key: String) -> String {
        return LCPermissionManager.bundle.localizedString(forKey: key, value: "", table: "LCPermissionManager")
    }
    
    
    
    /// 应用名称
    static let appName: String = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
    Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
    Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String ??
    Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    
    
    
    
    /// 从 LCPermissionManager 的资源 bundle 中加载图片
    /// - Parameter name: 图片文件名（包括扩展名）
    /// - Returns: 加载成功返回 NSImage，否则返回 nil
    static func bundleImage(_ name: String) -> NSImage? {
        // 加载主 bundle
        let bundle = LCPermissionManager.bundle

        // 尝试获取资源 bundle 的 URL
        guard let bundleURL = bundle.url(forResource: "LCPermissionManager", withExtension: "bundle"),
              let resourceBundle = Bundle(url: bundleURL) else {
            print("无法加载 LCPermissionManager.bundle")
            return nil
        }
        
        // 由于没有使用 cocoapods 导入，需要注释以下代码，才能正常显示图标
        // 深入查找嵌套的 LCPermissionManager.bundle
        guard let nestedBundleURL = resourceBundle.url(forResource: "LCPermissionManager", withExtension: "bundle"),
              let nestedBundle = Bundle(url: nestedBundleURL) else {
            print("无法加载嵌套的 LCPermissionManager.bundle")
            return nil
        }

        // 拼接图片路径
        guard let imagePath = nestedBundle.path(forResource: name, ofType: nil) else {
            print("无法找到图片 \(name) 在 LCPermissionManager.bundle 中")
            print("嵌套 Bundle 路径: \(resourceBundle.bundlePath)")
            return nil
        }

        // 加载图片
        return NSImage(contentsOfFile: imagePath)
    }
    
}
