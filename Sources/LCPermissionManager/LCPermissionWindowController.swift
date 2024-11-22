//
//  LCPermissionWindowController.swift
//
//  Created by DevLiuSir on 2023/11/22.
//


import Cocoa


class LCPermissionWindowController: NSWindowController {

    // 权限视图控制器
    public lazy var permissionVC: LCPermissionViewController = {
        let vc = LCPermissionViewController()
        return vc
    }()

    // 初始化方法
    override init(window: NSWindow?) {
        // 初始化窗口属性
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .fullSizeContentView, .closable, .miniaturizable],
            backing: .buffered,
            defer: true
        )
        super.init(window: window)
        
        // 设置窗口外观
        self.window?.titlebarAppearsTransparent = true // 隐藏标题栏背景
        self.window?.title = String(format: LCPermissionManager.localizeString("Permission Title"), kAppName) // 设置窗口标题
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true // 隐藏缩放按钮
        self.window?.isOpaque = false   // 允许透明背景
        self.window?.isMovableByWindowBackground = true // 允许拖动窗口背景移动
        self.window?.contentViewController = self.permissionVC // 设置内容视图控制器
        self.window?.center() // 窗口居中显示
    }
    
    // 必须实现的初始化器
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
