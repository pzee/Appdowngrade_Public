//
//  LoginView.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Localize_Swift

typealias LoginViewLoginBlock = ()->Void

class ADLoginView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var loginBlock:LoginViewLoginBlock?
    
    var appleId:String{
        return emailView.text ?? ""
    }
    var password:String {
        return passwordView.text ?? ""
    }
    var code:String {
        return codeView.text ?? ""
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        
    }
    
    private func setupUI() {
        // 设置主视图背景色
        backgroundColor = .kk_hex("#F7F7F7", alpha: 1.0)
        
        // 添加子视图
        addSubview(emailView)
        addSubview(passwordView)
        addSubview(codeView)
        addSubview(loginButton)
        addSubview(titleLabel)
        addSubview(disclaimerLabel)
        
        // 设置输入框背景色
        let inputBackgroundColor:UIColor = .kk_hex("#EFEFEF", alpha: 1.0)
        emailView.contentView .backgroundColor = inputBackgroundColor
        passwordView.contentView .backgroundColor = inputBackgroundColor
        codeView.contentView .backgroundColor = inputBackgroundColor
        
        // 设置登录按钮渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.kk_hex("#6b7de6", alpha: 1.0).cgColor,
            UIColor.kk_hex("#4b61e3", alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        loginButton.layer.insertSublayer(gradientLayer, at: 0)
        loginButton.layer.cornerRadius = 22 // 高度的一半，使按钮圆润
        loginButton.clipsToBounds = true
        
        // 设置约束
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        emailView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        passwordView.snp.makeConstraints { make in
            make.top.equalTo(emailView.snp.bottom).offset(20)
            make.leading.trailing.height.equalTo(emailView)
        }
        
        codeView.snp.makeConstraints { make in
            make.top.equalTo(passwordView.snp.bottom).offset(20)
            make.leading.trailing.height.equalTo(emailView)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(codeView.snp.bottom).offset(30)
            make.leading.trailing.equalTo(emailView)
            make.height.equalTo(44)
        }
        
        disclaimerLabel.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(30)
        }
        
        //
        emailView.placeholder = kAD_Apple_ID.localized()
        passwordView.placeholder = kAD_Apple_Password.localized()
        codeView.placeholder = kAD_Code_Placeholder.localized()
        loginButton.setTitle(kAD_Login.localized(), for: .normal)
        
    }
    
    // 添加布局子视图方法来更新渐变层的frame
    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = loginButton.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = loginButton.bounds
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    lazy var emailView: ADLoginInputView = {
        let view = ADLoginInputView()
        let emailImage = UIImage(systemName: "envelope")?.withRenderingMode(.alwaysTemplate)
        view.image = emailImage
        return view
    }()
    
    lazy var passwordView: ADLoginInputView = {
        let view = ADLoginInputView()
        let lockImage = UIImage(systemName: "lock")?.withRenderingMode(.alwaysTemplate)
        view.image = lockImage
        view.secureTextEntry = true
        view.configureSecureTextEntry(true)
        return view
    }()
    
    lazy var codeView: ADLoginInputView = {
        let view = ADLoginInputView()
        let shieldImage = UIImage(systemName: "shield")?.withRenderingMode(.alwaysTemplate)
        view.image = shieldImage
        return view
    }()

    lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else {return}
            self.loginBlock?()
        }).disposed(by: rx.disposeBag)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = kAD_Apple_Login.localized()
        label.font = .boldSystemFont(ofSize: 28)
        label.textAlignment = .center
        label.textColor = .kk_hex("#333333", alpha: 1.0)
        return label
    }()

    private lazy var disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = kAD_Data_Lost.localized()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .kk_hex("#999999", alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
}
