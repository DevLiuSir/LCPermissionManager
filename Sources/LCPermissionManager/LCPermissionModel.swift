//
//  LCPermissionModel.swift
//
//  Created by DevLiuSir on 2023/11/22.
//



import Foundation


/// 权限授权类型
enum LCPermissionAuthType: Int {
    case none                 // 无
    case accessibility        // 辅助功能权限
    case fullDisk             // 完全磁盘权限
    case screenCapture        // 录屏
}

/// 权限模型
class LCPermissionModel {
    
    /// 授权类型
    var authType: LCPermissionAuthType
    
    /// 文字描述
    var desc: String
    
    /// 初始化方法
    /// - Parameters:
    ///   - authType: 授权类型
    ///   - desc: 文字描述权限的作用
    init(authType: LCPermissionAuthType, desc: String) {
        self.authType = authType
        self.desc = desc
    }
    
    /// 工厂方法，用于创建 `LCPermissionModel` 实例
    /// - Parameters:
    ///   - authType: 授权类型
    ///   - desc: 文字描述
    /// - Returns: 一个新的 `LCPermissionModel` 实例
    static func model(with authType: LCPermissionAuthType, desc: String) -> LCPermissionModel {
        return LCPermissionModel(authType: authType, desc: desc)
    }
}
