//
//  Copyright © 2016年 xiAo_Ju. All rights reserved.
//

let PASSWORD_KEY = "gesture_password_key_"

public struct LockCenter {

    static var storage: Storagable = LockUserDefaults()
    static let lockTime = [1, 5, 30, 60, 180, 720, 1440]
    
    public static func hasPassword(for key: String? = nil) -> Bool {
        return storage.str(forKey: suffix(with: key)) != nil
    }

    public static func removePassword(for key: String? = nil) {
        storage.removeValue(forKey: suffix(with: key))
        removeErrorTimes(forKey: LockCenter.passwordKeySuffix)
    }

    public static func set(_ password: String, forKey key: String? = nil) {
        storage.set(password, forKey: suffix(with: key))
    }
    
    public static func password(forKey key: String? = nil) -> String? {
        return storage.str(forKey: suffix(with: key))
    }
    
    public static func passwordImage() -> UIImage? {
        if let passwordImagePath = passwordImagePath(),
            FileManager.default.fileExists(atPath: passwordImagePath + "/password.png") {
            return UIImage(contentsOfFile: passwordImagePath + "/password.png")
        }
        return nil
    }
    
    public static func passwordBackupTime() -> Date? {
        if let interval = UserDefaults.standard.object(forKey: "password_backup_time") as? Double, interval > 0 {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }
    
    public static func passwordBackupSucceed() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "password_backup_time")
    }
    
    public static func savePasswordImage(image: UIImage) {
        if let passwordImagePath = passwordImagePath(),
            let imageData = image.pngData() {
            do {
                if FileManager.default.fileExists(atPath: passwordImagePath + "/password.png") {
                    try FileManager.default.removeItem(atPath: passwordImagePath + "/password.png")
                }
                if NSData(data: imageData).write(toFile: passwordImagePath + "/password.png", atomically: true) {
                    UserDefaults.standard.removeObject(forKey: "password_backup_time")
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }

    private static func passwordImagePath()->String? {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last else {
            return nil
        }
        if !FileManager.default.fileExists(atPath: documentPath + "/password") {
            do {
                try FileManager.default.createDirectory(atPath: documentPath + "/password", withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                print(error.localizedDescription)
                return nil
            }
        }
        return documentPath + "/password"
    }
    
    public static func setErrorTimes(_ value: Int, forKey key: String? = nil) {
        let key = errorTimesKey(with: key)
        storage.set(value, forKey: key)
        if value <= 0 {
            let index = min((-value), lockTime.count - 1)
            let lockMin = lockTime[index]
            setUnlockTime(Date().addingTimeInterval(TimeInterval(lockMin * 60)))
        }
    }
    
    public static func setUnlockTime(_ value: Date?, forKey key: String? = nil) {
        let key = unLockTimeKey(with: key)
        if let value = value {
            storage.set(Int(value.timeIntervalSince1970), forKey: key)
        }
        else {
            storage.removeValue(forKey: key)
        }
    }

    public static func errorTimes(forKey key: String? = nil) -> Int {
        let key = errorTimesKey(with: key)
        var result = storage.integer(forKey: key)
        if result == 0 && storage.str(forKey: key) == nil {
            result = errorTimes
            storage.set(result, forKey: key)
        }
        return result
    }
    
    public static func unLockTime(forKey key: String? = nil) -> Date? {
        let key = unLockTimeKey(with: key)
        let result = storage.integer(forKey: key)
        if result == 0 && storage.str(forKey: key) == nil {
            if let unlockTime = unlockTime {
                setUnlockTime(unlockTime)
                return unlockTime
            }
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(result))
    }

    public static func removeErrorTimes(forKey key: String? = nil) {
        let key = errorTimesKey(with: key)
        storage.removeValue(forKey: key)
        setUnlockTime(nil)
    }

    public static func errorTimesKey(with suffix: String?) -> String {
        return PASSWORD_KEY + "error_times_" + (suffix ?? LockCenter.passwordKeySuffix)
    }
    
    public static func unLockTimeKey(with suffix: String?) -> String {
        return PASSWORD_KEY + "unlock_time_" + (suffix ?? LockCenter.passwordKeySuffix)
    }

    private static func suffix(with str: String?) -> String {
        return PASSWORD_KEY + (str ?? LockCenter.passwordKeySuffix)
    }
}

extension LockCenter {
    /// 密码后缀
    public static var passwordKeySuffix = ""

    // MARK: - 存放格式
    public static var usingKeychain: Bool = false

    // MARK: - 设置密码（"设置手势密码"）
    public static var settingTittle = "setPasswordTitle".localized
    
    /// 设置密码提示文字（"绘制解锁图案"）
    public static var setPasswordDescTitle = "setPasswordDescTitle".localized
    
    /// 重绘密码提示文字（"再次绘制解锁图案"）
    public static var secondPassword = "setPasswordAgainTitle".localized
    
    /// 设置密码提示文字（"与上一次绘制不一致，请重新绘制"）
    public static var differentPassword = "setPasswordMismatchTitle".localized
    
    /// 设置密码重绘按钮（重绘）
    public static var redraw = "redraw".localized
    
    /// 最低设置密码数目
    public static var passwordMinCount = 4
    
    /// "至少连接$个点，请重新输入"
    public static func tooShortTitle(with count: Int = LockCenter.passwordMinCount) -> String {
        let title = "setPasswordTooShortTitle".localized
        return title.replacingOccurrences(of: "$", with: count.description)
    }
    
    public static func invalidPasswordTitle(with times: Int) -> String {
        let title = "invalidPasswordTitle".localized
        return title.replacingOccurrences(of: "$", with: times.description)
    }
    
    public static func tryAgainPasswordTitle() -> String {
        return "tryAgainPasswordTitle".localized
    }

    public static func stopUseTitle(stopTo time: Date) -> String {
        let title = "tryLaterPasswordTitle".localized
        return title.replacingOccurrences(of: "$", with: "\(Int(time.timeIntervalSinceNow/60) + 1)")
    }

    // MARK: - 验证密码
    
    /// 密码错误次数
    /// Default 5
    static var errorTimes = 5
    
    /// 密码错误次数过多后，停用时间
    static var unlockTime: Date?

    public static var verifyPasswordTitle = "verifyPasswordTitle".localized
    
    public static var forgotBtnTitle = "forgotParttern".localized
    
    
    // MARK: - 修改密码
    
    //
    public static var resetPatternTitle = "resetPatternTitle".localized
    
    // MARK: - UI
    
    /// 圆的半径
    /// Default: 66
    public static var itemDiameter: CGFloat = 66
    
    /// 选中圆大小的线宽
    /// Default: 1
    public static var lineWidth: CGFloat = 1
    
    /// 背景色
    /// Default: UIColor(r: 255, g: 255, b: 255)
    public static var backgroundColor = UIColor(r: 255, g: 255, b: 255)
    
    /// 外环线条颜色：默认
    /// Default: UIColor(r: 173, g: 216, b: 230)
    public static var lineNormalColor = UIColor(r: 173, g: 216, b: 230)
    
    /// 外环线条颜色：选中
    /// Default: UIColor(r: 0, g: 191, b: 255)
    public static var lineHighlightColor = UIColor(r: 0, g: 191, b: 255)
    
    /// 外环线条颜色：错误
    /// Default: warningTitleColor
    public static var lineWarnColor = warningTitleColor

    /// 警示文字颜色
    /// Default: UIColor.red
    public static var warningTitleColor = UIColor.red
    
    /// 普通文字颜色
    /// Default: UIColor(r: 192, g: 192, b: 192)
    public static var normalTitleColor = UIColor(r: 51, g: 51, b: 51)
    
    /// 导航栏titleColor
    /// Default: UIColor.black
    public static var barTittleColor = UIColor.black
    
    /// 导航栏底部黑线是否隐藏
    /// Default: false
    public static var hideBarBottomLine = false
    
    /// barButton文字颜色
    /// Default: UIColor.red
    public static var barTintColor = UIColor.red
    
    /// barButton文字大小
    /// Default: UIFont.systemFont(ofSize: 18)
    public static var barTittleFont = UIFont.systemFont(ofSize: 18)
    
    /// 导航栏背景颜色
    /// Default: nil
    public static var barBackgroundColor: UIColor?
    
    /// 状态栏字体颜色
    /// Default: UIStatusBarStyle.default
    public static var statusBarStyle: UIStatusBarStyle = .default
}

@discardableResult
public func showSetPattern(in controller: UIViewController) -> SetPatternController {
    let vc = SetPatternController()
    controller.navigationController?.pushViewController(vc, animated: true)
    return vc
}

@discardableResult
public func showVerifyPattern(in controller: UIViewController) -> VerifyPatternController {
    let vc = VerifyPatternController()
    controller.present(LockMainNav(rootViewController: vc), animated: false, completion: nil)
    return vc
}

@discardableResult
public func showModifyPattern(in controller: UIViewController) -> ResetPatternController {
    let vc = ResetPatternController()
    controller.navigationController?.pushViewController(vc, animated: true)
    return vc
}

func delay(_ interval: TimeInterval, handle: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: handle)
}
