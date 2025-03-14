//
//  ADSettingsHeaderView.swift
//  AppDowngrade
//
//  Created by dev on 3/14/25.
//

import UIKit
import SnapKit

class ADSettingsHeaderView: UICollectionReusableView {
    static let identifier = "ADSettingsHeaderView"
    
    // MARK: - UI组件
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        addSubview(titleLabel)
        
        // 使用 SnapKit 设置约束 - 适配 RTL
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - 配置方法
    func configure(with title: String) {
        titleLabel.text = title
    }
} 
