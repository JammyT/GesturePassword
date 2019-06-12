//
//  SetPasswordController.swift
//  GesturePassword
//
//  Created by 黄伯驹 on 2018/4/21.
//  Copyright © 2018 xiAo_Ju. All rights reserved.
//

import Foundation

public final class SetPatternController: UIViewController {

    public var successHandle: ((String) -> Void)?

    private let contentView = UIView()
    var originNavigationBarIsHidden: Bool = false
    private let lockInfoView = LockInfoView()
    private let lockDescLabel = LockDescLabel()
    public let lockMainView = LockView()
    let tipsLabel: UILabel = {
        let label = UILabel()
        label.text = "请牢记设置的密码，为了安全，我们不上传你的密码，因此我们无法提供找回密码功能。"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.red
        label.numberOfLines = 0
        return label
    }()

    public var password = ""

    override public func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LockCenter.settingTittle

        view.backgroundColor = LockCenter.backgroundColor

        view.addSubview(contentView)
        contentView.backgroundColor = .white
        contentView.widthToSuperview().centerY(to: view, constant: 32)

        initUI()
        
        view.addSubview(tipsLabel)
        tipsLabel.top(to: contentView, attribute:.bottom, constant: 20).widthToSuperview(constant: -40).centerXToSuperview()
        
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originNavigationBarIsHidden = self.navigationController?.isNavigationBarHidden ?? false
        self.navigationController?.isNavigationBarHidden = false
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = originNavigationBarIsHidden
    }
    
    private func showRedrawBarButton() {
        if password.isEmpty { return }
        let redraw = UIBarButtonItem(title: LockCenter.redraw, style: .plain, target: self, action: #selector(redrawAction))
        navigationItem.rightBarButtonItem = redraw
    }
    
    private func processErrorState() {
        lockMainView.warn()
        showRedrawBarButton()
    }
    

    private func hiddenRedrawBarButton() {
        navigationItem.rightBarButtonItem = nil
    }

    public func dismiss() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func redrawAction() {
        hiddenRedrawBarButton()

        LockAdapter.reset(with: self)
        lockDescLabel.showNormal(with: LockCenter.setPasswordDescTitle)
        lockInfoView.reset()
    }

    private func initUI() {
        contentView.addSubview(lockInfoView)
        contentView.addSubview(lockDescLabel)
        contentView.addSubview(lockMainView)
        lockInfoView.topToSuperview()
            .centerXToSuperview()
            .width(to: contentView, multiplier: 1 / 8)
            .height(to: lockInfoView, attribute: .width)

        lockDescLabel.top(to: lockInfoView,
                          attribute: .bottom,
                          constant: 30).centerXToSuperview()
        lockDescLabel.showNormal(with: LockCenter.setPasswordDescTitle)

        lockMainView.delegate = self
        lockMainView.top(to: lockDescLabel,
                         attribute: .bottom,
                         constant: 30)
            .centerXToSuperview()
            .bottomToSuperview()
            .height(to: lockMainView, attribute: .width)
    }
}

extension SetPatternController: LockViewDelegate {
    public func lockViewDidTouchesEnd(_ lockView: LockView) {
        
        LockAdapter.setPattern(with: self)
    }
}

extension SetPatternController: SetPatternDelegate {

    public func firstDrawedState() {
        lockInfoView.showSelectedItems(lockMainView.password)
        lockDescLabel.showNormal(with: LockCenter.secondPassword)
    }

    public func tooShortState() {
        processErrorState()
        let text = LockCenter.tooShortTitle()
        lockDescLabel.showWarn(with: text)
    }

    public func mismatchState() {
        processErrorState()
        lockDescLabel.showWarn(with: LockCenter.differentPassword)
    }

    public func successState() {
        if let passwordImage = lockMainView.screenshot() {
            LockCenter.savePasswordImage(image: passwordImage)
        }
        successHandle?(password)
        dismiss()
    }
}
