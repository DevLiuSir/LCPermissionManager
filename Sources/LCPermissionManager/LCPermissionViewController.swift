//
//  LCPermissionViewController.swift
//
//  Created by DevLiuSir on 2023/11/22.
//


import Cocoa



/// 单个权限项的高度
/// - 用于计算权限视图的布局和窗口高度
private let kPermissionItemHeight: CGFloat = 50

/// 权限项之间的间距
/// - 确保各权限项之间有足够的视觉间隔，提升界面可读性
private let kPermissionItemGap: CGFloat = 25



// MARK: - 翻转视图
class LCPermissionView: NSView {
    override var isFlipped: Bool {
        return true
    }
}



// MARK: - 自定义 Box
class LCPermissionBoxView: NSBox {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.boxType = .custom
        self.titlePosition = .noTitle
        self.cornerRadius = 15
        self.borderWidth = 0
        self.contentViewMargins = NSSize.zero
        self.setBackgroundColor()
        NSApp.addObserver(self, forKeyPath: "effectiveAppearance", options: .new, context: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSApp.removeObserver(self, forKeyPath: "effectiveAppearance")
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "effectiveAppearance" {   // effectiveAppearance可以监听系统外观模式的变化。
            self.setBackgroundColor()
        }
    }
    
    /// 设置背景颜色
    private func setBackgroundColor() {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            // 暗黑模式
            self.fillColor = NSColor(white: 0, alpha: 0.15)
        } else {
            self.fillColor = NSColor(white: 1, alpha: 0.4)
        }
    }
}



// MARK: - 权限设置控制器
class LCPermissionViewController: NSViewController {
    
    /// 模糊视图
    private lazy var effectView: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        return view
    }()
    
    /// 标题文本
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: String(format: LCPermissionManager.localizeString("Permission sub Title"), kAppName))
        label.font = NSFont.systemFont(ofSize: 15)
        return label
    }()
    
    /// 自定义NSBoxView
    private lazy var box: LCPermissionBoxView = {
        return LCPermissionBoxView()
    }()
    
    /// 查看权限设置教程按钮
    private lazy var lookBtn: NSButton = {
        let button = NSButton(title: LCPermissionManager.localizeString("View permission setting tutorail"), target: self, action: #selector(lookTutorialVideo))
        button.bezelColor = NSColor.controlAccentColor
        // 如果没有教程链接，隐藏按钮
        button.isHidden = LCPermissionManager.shared.tutorialLink.isEmpty
        return button
    }()
    
    /// 退出应用按钮
    private lazy var quitBtn: NSButton = {
        return NSButton(title: LCPermissionManager.localizeString("Quit App"), target: self, action: #selector(quitApp))
    }()
    
    /// 跳过按钮
    private lazy var skipBtn: NSButton = {
        return NSButton(title: LCPermissionManager.localizeString("Skip"), target: self, action: #selector(skip))
    }()
    
    
    /// 权限类型数组，当设置新值时，会自动更新视图内容
    var authTypes: [LCPermissionModel] = [] {
        didSet {
            // 移除旧的授权项视图
            self.box.contentView?.subviews.forEach { $0.removeFromSuperview() }
            // 添加新的授权项视图
            for model in authTypes {
                // 创建对应的授权项视图
                let item = LCPermissionItem.item(with: model)
                // 将授权项视图添加到box内容视图中
                self.box.contentView?.addSubview(item)
            }
            // 更新窗口高度
            var frame = self.view.window?.frame ?? NSRect.zero
            frame.size.height = CGFloat(authTypes.count) * kPermissionItemHeight + CGFloat(authTypes.count + 1) * kPermissionItemGap + 180
            self.view.window?.setFrame(frame, display: true)        // 更新窗口大小
            self.view.needsLayout = true            // 标记需要重新布局
        }
    }
    
    
    /// 所有权限通过后的，处理回调
    var allAuthPassedHandler: (() -> Void)?
    
    /// 跳过权限检查后的处理，回调
    var skipHandler: (() -> Void)?
    
    
    /**
     * 重写 `loadView` 方法以自定义视图加载逻辑。
     *
     * 调用时机：
     * - 视图控制器的 `view` 属性被访问时，如果尚未加载视图。
     *
     * 作用：
     * - 自定义主视图的初始化，避免使用 Interface Builder 或 Storyboard。
     * - 手动创建并设置视图层次结构。
     * - 添加并配置子视图。
     *
     * 注意事项：
     * - `loadView` 方法会覆盖默认的视图加载逻辑，因此需要确保 `self.view` 被正确设置。
     * - 不应在此方法中调用 `super.loadView()`。
     */
    override func loadView() {
        self.view = LCPermissionView(frame: NSRect(x: 0, y: 0, width: 600, height: 300))
        self.view.addSubview(effectView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(box)
        self.view.addSubview(lookBtn)
        self.view.addSubview(quitBtn)
        self.view.addSubview(skipBtn)
    }
    
    /**
     * `viewDidLayout` 方法在视图布局完成后被调用。
     *
     * 调用时机：
     * - 视图层级发生变化时，例如子视图的添加或移除。
     * - 视图的 frame 或 bounds 发生改变时，例如窗口大小调整。
     * - 手动调用 `setNeedsLayout()` 或 `layoutSubtreeIfNeeded()` 方法后。
     *
     * 作用：
     * - 在这里可以更新子视图的布局，确保它们根据当前视图的尺寸正确调整位置和大小。
     * - 通常用于动态调整子视图的位置和大小，响应窗口或父视图的变化。
     */
    override func viewDidLayout() {
        super.viewDidLayout()
        
        // 设置模糊背景效果视图的大小与父视图一致
        effectView.frame = view.bounds
        
        // 标题标签布局
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(x: view.frame.width / 2 - titleLabel.frame.width / 2, y: 60)
        
        // 权限项容器Box布局
        box.frame = NSRect(x: 40, y: titleLabel.frame.maxY + 20, width: view.frame.width - 80, height: CGFloat(authTypes.count) * kPermissionItemHeight + CGFloat(authTypes.count + 1) * kPermissionItemGap)
        
        // 布局权限项
        var top = kPermissionItemGap
        for subview in box.contentView?.subviews.reversed() ?? [] {
            if let item = subview as? LCPermissionItem {
                item.frame = NSRect(x: 30, y: top, width: box.contentView!.frame.width - 60, height: kPermissionItemHeight)
                top = item.frame.maxY + kPermissionItemGap
            }
        }
        
        // 布局底部按钮
        lookBtn.sizeToFit()
        quitBtn.sizeToFit()
        skipBtn.sizeToFit()
        
        lookBtn.frame.origin = NSPoint(x: box.frame.minX, y: box.frame.maxY + 10)
        skipBtn.frame.origin = NSPoint(x: box.frame.maxX - skipBtn.frame.width, y: lookBtn.frame.minY)
        quitBtn.frame.origin = NSPoint(x: skipBtn.frame.minX - quitBtn.frame.width - 10, y: lookBtn.frame.minY)
    }
    
    /// 刷新所有授权状态
    func refreshAllAuthState() {
        // 初始化状态标志，表示所有授权是否通过
        var all = true
        
        // 遍历所有子视图，检查授权状态
        for subview in box.contentView?.subviews ?? [] {
            if let item = subview as? LCPermissionItem {
                // 更新授权状态，并更新全局状态标志
                all = item.refreshStatus() && all
            }
        }
        
        // 如果所有授权状态均通过，触发回调
        if all {
            allAuthPassedHandler?()
        }
    }
    
    //MARK: - Actions
    /// 退出应用
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    /// 跳过权限设置
    @objc private func skip() {
        skipHandler?()
    }
    
    /// 查看权限设置教程
    @objc private func lookTutorialVideo() {
        if let url = URL(string: LCPermissionManager.shared.tutorialLink) {
            NSWorkspace.shared.open(url)
        }
    }
    
}
