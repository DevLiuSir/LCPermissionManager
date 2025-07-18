//
//  AppDelegate.swift
//  LCPermissionManagerDemo
//
//  Created by DevLiuSir on 2023/11/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let model = LCPermissionModel(authType: .accessibility, desc: "用于显示悬浮窗口操作面板")
        let model2 = LCPermissionModel(authType: .fullDisk, desc: "用于显示浮窗")
        let model3 = LCPermissionModel(authType: .screenCapture, desc: "用于显示窗口的缩略图")
        LCPermissionManager.shared.monitorPermissionAuthTypes([model, model2, model3], repeat: 2)
        // 观看权限链接，不设置，就不显示按钮
        LCPermissionManager.shared.tutorialLink = "https://www.better365.cn/tv.html"
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

