//
//  HomeView.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Localize_Swift

//枚举（适配OC调用）
/*
@objc enum DemoType: NSInteger {
    case Type1 = 0
    case Type2 = 1
}
*/

//block定义
//typealias DemoBlock = (_ avg: NSInteger) -> Void


protocol ADHomeViewDelegate: AnyObject {
    func homeViewDidClickButton(_ sender: ADHomeView,type:ADHomeViewType)
}

enum ADHomeViewType {
    case Login
    case Logout
    case Downgrade
}

class ADHomeView: UIView {
    deinit {
//        printLog("*******************控制器释放【\(Swift.type(of: self))】*******************")
        NotificationCenter.default.removeObserver(self)
    }

    
    
    // MARK: - 【参数】let/var
    // UI
    // Model
    // ViewModel
    // Layout
    // Foundation
    // Constant/Frame
    // Block
    // BOOL
    // Others
    weak var delegate: ADHomeViewDelegate?
    var link: String?{
        get{
            return self.inputTextField.text
        }
    }
    
     // MARK: - 【自定义初始化】init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    /*
    //自定义初始化方法
     public init(withFrame frame:CGRect, avg1: NSInteger) {
         super.init(frame: frame)
         self.setup()
     }
    */
    
    //初始化
    func setup() {
        //配置初始化
        self.setupConfig()
        //UI初始化
        self.setupUI()
        //点击操作
        self.setupAction()
        //请求加载数据
        self.setupDataRequest()
    }
    //配置初始化
    func setupConfig() {
        
    }
    //UI初始化
    func setupUI() {
        // 添加子视图
       
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(inputContentView)
        addSubview(downgradeButton)
        addSubview(loginButton)
        addSubview(logoutButton)
        addSubview(tipLabel)
        addSubview(userLabel)
        
        // 将输入框添加到inputContentView
        inputContentView.addSubview(inputTextField)
        
        
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(100)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        inputContentView.snp.makeConstraints { make in
            make.top.equalTo(self.detailLabel.snp.bottom).offset(40)
//            make.centerY.equalTo(self)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        inputTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        
        downgradeButton.snp.makeConstraints { make in
            make.top.equalTo(inputContentView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(downgradeButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(downgradeButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        userLabel.snp.makeConstraints { make in
            make.top.equalTo(logoutButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        tipLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self).offset(-(UIScreen.kk.tabBarHeight + UIScreen.kk.safeAreaBottom + 60))
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        // 设置默认状态
        
        loginButton.isHidden = false
        logoutButton.isHidden = true
        
        // 设置圆角
        inputContentView.layer.cornerRadius = 20
        inputContentView.layer.masksToBounds = true
        inputContentView.backgroundColor = .white
        inputContentView.layer.borderWidth = 1
        inputContentView.layer.borderColor = UIColor.lightGray.cgColor
        
        // 设置按钮圆角和渐变色
        [downgradeButton, loginButton, logoutButton].forEach { button in
            button.layer.cornerRadius = 22
            button.layer.masksToBounds = true
        }
        
        // 使用UIView+CAGradientLayer方法设置渐变色
        // 降级按钮渐变色 (更淡的蓝色系)
        downgradeButton.kk_addGradient(
            colors: [UIColor.kk_hex("#66A9FF", alpha: 1.0), UIColor.kk_hex("#6685FF", alpha: 1.0)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1))
        
        downgradeButton.setTitleColor(.white, for: .normal)
        
        // 登录按钮渐变色 (更淡的绿色系)
        loginButton.kk_addGradient(
            colors: [UIColor.kk_hex("#7DDC93", alpha: 1.0), UIColor.kk_hex("#7DCF8E", alpha: 1.0)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        loginButton.setTitleColor(.white, for: .normal)
        
        // 退出按钮渐变色 (更淡的红色系)
        logoutButton.kk_addGradient(
            colors: [UIColor.kk_hex("#FF8A83", alpha: 1.0), UIColor.kk_hex("#FF7A74", alpha: 1.0)],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        logoutButton.setTitleColor(.white, for: .normal)
        
        setupUIContent()
    }
    
    func setupUIContent() {
        
        self.titleLabel.text = kAD_Downgrade_Title.localized()
        self.detailLabel.text = kAD_Downgrade_Detail.localized()
        self.inputTextField.placeholder = kAD_App_Link.localized()
        self.tipLabel.text = kAD_Data_Lost.localized()
    }
    
    //点击操作
    func setupAction() {
        
    }
    
    // MARK: - 【重写系统方法】override system method

    // MARK: - 【重写父类方法】override father method
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新渐变层的frame - 不再需要手动更新，UIView+CAGradientLayer扩展会处理
        // 如果需要，可以调用refreshGradientLayer方法
        downgradeButton.kk_updateGradientFrame()
        loginButton.kk_updateGradientFrame()
        logoutButton.kk_updateGradientFrame()
    }
    // MARK: - 【selector方法】target-action

    // MARK: - 【私有方法】 private method

    // MARK: - 【公开方法】public method
    func updateLoginButtonState(isLogin: Bool) {
        loginButton.isHidden = isLogin
        logoutButton.isHidden = !isLogin
    }
    
    func updateUserAppId(appleId:String) -> Void {
        if appleId.isEmpty {
            self.userLabel.text = kAD_Not_Login.localized()
        }else{
            self.userLabel.text = String(format: kAD_CurrentUser.localized(), appleId)
        }
        
    }
     
    // MARK: - 【自定义代理】custom delegate

    // MARK: - 【系统代理】system delegate

    // MARK: - 【数据请求】API
    //请求加载数据
    func setupDataRequest() {
        
    }

    // MARK: - 【懒加载】lazy
    
    
    
    private lazy var titleLabel: UILabel = {
       let label = UILabel()
        label.textColor = UIColor.kk_hex("#2C3E50", alpha: 1.0)  // 深蓝灰色
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.kk_hex("#7F8C8D", alpha: 1.0)  // 中灰色
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
    
    private lazy var inputContentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.clearButtonMode = .whileEditing
        textField.textColor = .black
        return textField
    }()
    
    private lazy var downgradeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(kAD_Downgrade.localized(), for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else {return}
            self.delegate?.homeViewDidClickButton(self,type: .Downgrade)
        }).disposed(by:rx.disposeBag)
        return button
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(kAD_Login.localized(), for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else {return}
            self.delegate?.homeViewDidClickButton(self,type: .Login)
        }).disposed(by:rx.disposeBag)
        return button
    }()
    
    private lazy var logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(kAD_Logout.localized(), for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else {return}
            self.delegate?.homeViewDidClickButton(self,type: .Logout)
        }).disposed(by:rx.disposeBag)
        return button
    }()
    
    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private lazy var userLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.kk_hex("#7F8C8D", alpha: 1.0)  // 中灰色
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - 【getter & setter】

    // MARK: - 【frame/font/color】let/var
    struct Constants {
        //frame
        struct Frame {
            //static let kWidth: CGFloat = 10.0
        }
        //font
        struct Font {
            //static let kFont: UIFont = .boldSystemFont(ofSize: 16.0)
        }
        //color
        struct Color {
            //static let kColor: UIColor = UIColor.hexColor(0xFFFFFF)
        }
    }

}
