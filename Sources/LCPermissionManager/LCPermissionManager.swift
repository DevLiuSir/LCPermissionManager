//
//  LCPermissionManager.swift
//
//  Created by DevLiuSir on 2023/11/22.
//

import Cocoa


// 获取应用名称
public let kAppName: String = {
    let bundle = Bundle.main
    return bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String
    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
    ?? bundle.localizedInfoDictionary?["CFBundleName"] as? String
    ?? bundle.infoDictionary?["CFBundleName"] as? String
    ?? "Unknown App Name" // 默认值，如果无法获取应用名称
}()




public class LCPermissionManager: NSObject {
    
    /// 单例
    public static let shared = LCPermissionManager()
    
    /// 权限窗口控制器
    /// - 用于显示权限设置窗口
    private var permissionWC: LCPermissionWindowController?
    
    /// 权限类型数组
    /// - 保存当前需要检测或设置的权限类型
    private var authTypes: [LCPermissionModel] = []
    
    /// 权限状态监控定时器
    /// - 用于定时刷新和检测权限状态
    private var monitorTimer: Timer?
    
    /// 是否已跳过权限设置
    /// - 标记用户是否选择跳过权限设置
    //    private var skipped = false
    
    
    
    /// 是否已跳过权限设置（私有存储属性）
    private var _skipped = false
    
    /// 是否已跳过权限设置（只读属性）
    /// - 标记用户是否选择跳过权限设置
    public var skipped: Bool {
        return _skipped
    }
    
    /// 权限设置教程链接
    /// - 提供给用户查看权限设置教程的视频或网页链接
    public var tutorialLink: String = ""
    
    /// 所有权限通过后的回调
    /// - 当所有权限都已开启时调用
    var allAuthPassedHandler: (() -> Void)?
    
    // MARK: - 定时监听权限
    public func monitorPermissionAuthTypes(_ authTypes: [LCPermissionModel], repeat repeatSeconds: Int = 0) {
        self.authTypes = authTypes
        monitorTimer?.invalidate()
        
        var second = 0
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if repeatSeconds <= 0 {
                // 不需要循环监测
                if self.allAuthPassed() {
                    self.monitorTimer?.invalidate()
                    self.monitorTimer = nil
                    if self.permissionWC != nil {
                        self.passAuth()
                    }
                    return
                }
                
                // 有权限未授权，弹出授权窗口
                if self.permissionWC == nil {
                    self.showPermissionWindow(authTypes)
                } else {
                    self.permissionWC?.permissionVC.refreshAllAuthState()
                }
                self.permissionWC?.window?.makeKeyAndOrderFront(nil)
            } else {
                
                second += 1
                
                if second >= repeatSeconds {
                    // 达到设置的间隔秒数
                    if !self.allAuthPassed() {
                        if self.permissionWC == nil {
                            self.showPermissionWindow(authTypes)
                        }
                        self.permissionWC?.window?.makeKeyAndOrderFront(nil)
                        second = 0
                    } else {
                        // 所有权限都已授权
                        if self.permissionWC != nil {
                            self.passAuth()
                        }
                    }
                } else if self.permissionWC != nil {
                    self.permissionWC?.permissionVC.refreshAllAuthState()
                }
            }
        }
    }
    
    // MARK: 显示权限窗口
    private func showPermissionWindow(_ authTypes: [LCPermissionModel]) {
        let permissionWC = LCPermissionWindowController()
        permissionWC.permissionVC.allAuthPassedHandler = { [weak self] in
            self?.passAuth()
        }
        permissionWC.permissionVC.skipHandler = { [weak self] in
            self?.skipAuth()
        }
        permissionWC.permissionVC.authTypes = authTypes
        self.permissionWC = permissionWC
    }
    
    // MARK: - 权限都已通过
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
        _skipped = true
    }
    
    // MARK: 检查某个权限是否开启
    public static func checkPermissionAuthType(_ authType: LCPermissionAuthType) -> Bool {
        var isAuthorized = true
        var tips = ""
        var selector: Selector? = nil
        
        switch authType {
        case .accessibility:
            isAuthorized = getPrivacyAccessibilityIsEnabled()
            tips = "Accessibility Tips"
            selector = #selector(openPrivacyAccessibilitySetting)
        case .screenCapture:
            isAuthorized = getScreenCaptureIsEnabled()
            tips = "ScreenCapture Tips"
            selector = #selector(openScreenCaptureSetting)
        case .fullDisk:
            isAuthorized = getFullDiskAccessIsEnabled()
            tips = "Full disk access Tips"
            selector = #selector(openFullDiskAccessSetting)
        case .none:
            break
        }
        // 未授权，弹窗
        if !isAuthorized {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = localizeString("Kind tips")
            alert.informativeText = String(format: localizeString(tips), kAppName)
            alert.addButton(withTitle: localizeString("To Authorize"))
            alert.addButton(withTitle: localizeString("Cancel"))
            
            if alert.runModal() == .alertFirstButtonReturn, let selector = selector {
                perform(selector)
            }
        }
        return isAuthorized
    }
    
    // MARK: 获取所有权限是否已授权
    public func allAuthPassed() -> Bool {
        for model in authTypes {
            switch model.authType {
            case .accessibility:
                if !LCPermissionManager.getPrivacyAccessibilityIsEnabled() { return false }
            case .screenCapture:
                if !LCPermissionManager.getScreenCaptureIsEnabled() { return false }
            case .fullDisk:
                if !LCPermissionManager.getFullDiskAccessIsEnabled() { return false }
            case .none:
                break
            }
        }
        return true
    }
    
    // MARK: 获取辅助功能权限状态
    public static func getPrivacyAccessibilityIsEnabled() -> Bool {
        AXIsProcessTrusted()
    }
    
    
    // MARK: 打开辅助功能权限设置窗口
    @objc public func openPrivacyAccessibilitySetting() {
        // 模拟鼠标抬起事件，请求辅助功能权限
        if let eventRef = CGEvent(source: nil) {
            let point = eventRef.location
            if let mouseEventRef = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
                mouseEventRef.post(tap: .cghidEventTap)
            }
        }
        
        // 构造辅助功能权限设置的 URL
        let settingURLString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let settingURL = URL(string: settingURLString) {
            NSWorkspace.shared.open(settingURL)
        }
    }
    
    
    // MARK: 获取录屏权限状态
    public func getScreenCaptureIsEnabled() -> Bool {
        guard #available(macOS 10.15, *) else { return true }
        let currentPid = NSRunningApplication.current.processIdentifier
        // 获取当前屏幕上的窗口信息
        guard let windowList = CGWindowListCopyWindowInfo(.excludeDesktopElements, kCGNullWindowID) as? [[CFString: Any]] else { return false }
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
    
    // MARK: 获取完全磁盘权限状态
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
    
    // MARK: 打开完全磁盘权限设置窗口
    @objc public func openFullDiskAccessSetting() {
        let setting = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        NSWorkspace.shared.open(URL(string: setting)!)
    }
    
    
    // MARK: 本地化字符串
    static func localizeString(_ key: String) -> String {
        let bundle = Bundle(for: self)
        return bundle.localizedString(forKey: key, value: "", table: "LCPermissionManager")
    }
    
    
}
