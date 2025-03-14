//
//  ADSettingsCell.swift
//  AppDowngrade
//
//  Created by dev on 3/14/25.
//

import UIKit
import SnapKit

class ADSettingsCell: UICollectionViewCell {
    static let identifier = "ADSettingsCell"
    
    // MARK: - UI组件
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 10
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(accessoryImageView)
        
        // 使用 SnapKit 设置约束 - 适配 RTL
        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.trailing.equalTo(accessoryImageView.snp.leading).offset(-16)
        }
        
        accessoryImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(12)
            make.height.equalTo(20)
        }
    }
    
    // MARK: - 配置方法
    func configure(with item: ADSettingsItem) {
        titleLabel.text = item.title
        iconImageView.image = item.icon
        
        // 为 RTL 语言自动翻转箭头方向
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            accessoryImageView.image = UIImage(systemName: "chevron.left")
        } else {
            accessoryImageView.image = UIImage(systemName: "chevron.right")
        }
    }
} 
