//
//  LCPermissionModel.swift
//
//  Created by DevLiuSir on 2023/11/22.
//



import Cocoa


/// 权限项视图
class LCPermissionItem: NSView {
    
    /// 图标视图
    private lazy var iconView: NSImageView = {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        return view
    }()
    
    /// 勾选框按钮
    private lazy var checkButton: NSButton = {
        let button = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkButtonClicked))
        return button
    }()
    
    /// 信息标签
    private lazy var infoLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 10)
        label.textColor = .lightGray
        return label
    }()
    
    /// 授权按钮
    private lazy var authButton: NSButton = {
        let button = NSButton(title: LCPermissionManager.localizeString("Authorize"), target: self, action: #selector(authButtonClicked))
        button.bezelColor = .controlAccentColor
        return button
    }()
    
    
    /// 模型数据
    var model: LCPermissionModel? {
        didSet {
            guard let model = model else { return }
            switch model.authType {
            case .accessibility:
                // 辅助功能
                self.iconView.image = LCPermissionManager.bundleImage("Accessbility@2x.png")
                self.checkButton.title = LCPermissionManager.localizeString("Accessibility permission authorization")
            case .screenCapture:
                // 录屏
                self.iconView.image = LCPermissionManager.bundleImage("ScreenRecording@2x.png")
                self.checkButton.title = LCPermissionManager.localizeString("Screen recording permission authorization")
            case .fullDisk:
                // 完全磁盘
                self.iconView.image = LCPermissionManager.bundleImage("Folder@2x.png")
                self.checkButton.title = LCPermissionManager.localizeString("Full disk access authorization")
            default:
                break
            }
            self.infoLabel.stringValue = "*\(model.desc)"
            refreshStatus()
        }
    }
    
    
    /// 创建权限项
    /// - Parameter model: 权限模型
    /// - Returns: 创建的 LCPermissionItem 实例
    static func item(with model: LCPermissionModel) -> LCPermissionItem {
        let item = LCPermissionItem()
        item.model = model
        item.setupSubviews()
        return item
    }

    
    /// 初始化视图并添加子视图
    private func setupSubviews() {
        addSubview(iconView)
        addSubview(checkButton)
        addSubview(infoLabel)
        addSubview(authButton)
    }
    
    // 翻转视图
    override var isFlipped: Bool {
        return true
    }
    
    // 布局
    override func layout() {
        super.layout()
        
        // 图标布局
        let iconFrame = CGRect(x: 0, y: bounds.height / 2 - 25, width: 20, height: 20)
        iconView.frame = iconFrame
        
        // 勾选框布局
        checkButton.sizeToFit()
        let checkOrigin = CGPoint(x: iconFrame.maxX + 10, y: iconFrame.midY - checkButton.frame.height / 2)
        checkButton.frame.origin = checkOrigin
        
        // 信息标签布局
        infoLabel.sizeToFit()
        infoLabel.frame.origin = CGPoint(x: checkOrigin.x, y: bounds.height / 2 + 5)
        
        // 授权按钮布局
        authButton.sizeToFit()
        authButton.frame.origin = CGPoint(x: bounds.width - authButton.frame.width, y: bounds.height / 2 - authButton.frame.height / 2)
    }
    
    
    /// 刷新授权状态
    /// - Returns: 当前权限是否已授权
    @discardableResult
    func refreshStatus() -> Bool {
        let isAuthorized: Bool
        switch model?.authType {
        case .accessibility:
            isAuthorized = LCPermissionManager.getPrivacyAccessibilityIsEnabled()
        case .screenCapture:
            isAuthorized = LCPermissionManager.getScreenCaptureIsEnabled()
        case .fullDisk:
            isAuthorized = LCPermissionManager.getFullDiskAccessIsEnabled()
        default:
            isAuthorized = false
        }
        checkButton.state = isAuthorized ? .on : .off
        authButton.isHidden = isAuthorized
        return isAuthorized
    }
    
    /// 授权按钮点击事件
    @objc private func authButtonClicked() {
        switch model?.authType {
        case .accessibility:
            LCPermissionManager.shared.openPrivacyAccessibilitySetting()
        case .screenCapture:
            LCPermissionManager.shared.openScreenCaptureSetting()
        case .fullDisk:
            LCPermissionManager.shared.openFullDiskAccessSetting()
        default:
            break
        }
    }
    
    /// 勾选框点击事件
    @objc private func checkButtonClicked() {
        checkButton.state = checkButton.state == .on ? .off : .on
        authButtonClicked()
    }
    
}
