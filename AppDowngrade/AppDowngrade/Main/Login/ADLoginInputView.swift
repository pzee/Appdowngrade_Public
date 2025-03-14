//
//  LoginInputView.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa


class ADLoginInputView: UIView {
    
    var secureTextEntry: Bool = false
    private var _placeholder: String = ""
    var placeholder: String{
        
        set{
            _placeholder = newValue
            self.inputTextField.placeholder = _placeholder
        }
        get{
            return _placeholder
        }
    }
    private var _image: UIImage?
    var image:UIImage?{
        set {
            _image = newValue
            self.iconImageView.image = image
        }
        get{
            return _image
        }
    }
    var text:String?{
        get {
            return self.inputTextField.text
        }
        set {
            self.inputTextField.text = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 添加contentView
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 添加iconImageView
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        // 添加textField
        contentView.addSubview(inputTextField)
        inputTextField.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
    }

    // 添加contentView作为容器
    lazy var contentView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        return view
    }()
    
    // 添加imageView
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // 添加textField
    private lazy var inputTextField: UITextField = {
        let textField = UITextField()
//        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14)
        textField.isSecureTextEntry = self.secureTextEntry
        textField.clearButtonMode = .whileEditing
        textField.textColor = .black
        return textField
    }()
    
    private lazy var toggleButton: UIButton = {
        let button = UIButton(type: .custom)
        let eyeImage = UIImage(systemName: "eye")
        let eyeSlashImage = UIImage(systemName: "eye.slash")
        button.setImage(eyeImage, for: .normal)
        button.setImage(eyeSlashImage, for: .selected)
//        button.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else {return}
            self.toggleButtonTapped()
            
        }).disposed(by: rx.disposeBag)
        
        return button
    }()
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }
    
    func configureSecureTextEntry(_ isSecure: Bool) {
        inputTextField.isSecureTextEntry = isSecure
        
        if isSecure {
            // 添加按钮
            contentView.addSubview(toggleButton)
            toggleButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-15)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 30, height: 15))
            }
            
            // 更新输入框的约束
            inputTextField.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(10)
                make.trailing.equalTo(toggleButton.snp.leading).offset(-10)
                make.centerY.equalToSuperview()
                make.height.equalTo(20)
            }
        }
    }
    
    @objc private func toggleButtonTapped() {
        toggleButton.isSelected.toggle()
        inputTextField.isSecureTextEntry.toggle()
        
    }
}
