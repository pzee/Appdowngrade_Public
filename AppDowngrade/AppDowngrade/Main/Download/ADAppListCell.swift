//
//  AppListCell.swift
//  AppDowngrade
//
//  Created by dev on 3/6/25.
//

import UIKit
import SnapKit
import SwipeCellKit

let AppListCellIdentifier = "AppListCellIdentifier"
class ADAppListCell: SwipeCollectionViewCell {
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()
    
    var app:AppDetail?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Cell appearance
        contentView.backgroundColor = .white
//        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.1
        
        // Icon image view
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(systemName: "doc.fill")
        iconImageView.tintColor = .systemBlue
        contentView.addSubview(iconImageView)
        
        // Name label
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 2
        contentView.addSubview(nameLabel)
        
        // Size label
        sizeLabel.font = UIFont.systemFont(ofSize: 14)
        sizeLabel.textColor = .gray
        sizeLabel.textAlignment = .left
        contentView.addSubview(sizeLabel)
        
        // SnapKit constraints - horizontal layout
        iconImageView.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(15)
            make.width.height.equalTo(40)
        }
        
        nameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.top.equalTo(iconImageView.snp.top)
            make.trailing.equalTo(contentView).offset(-15)
            
        }
        
        sizeLabel.snp.remakeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.bottom.equalTo(iconImageView.snp.bottom)
            make.trailing.equalTo(contentView).offset(-15)
        }
    }
    
    func configure(with app: AppDetail) {
        self.app = app
        if app.displayName.isEmpty{
            nameLabel.text = app.appName
        }else{
            nameLabel.text = app.displayName
        }
        
        
        // Format file size
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        sizeLabel.text = String(format: "%@", app.version) + " / " + formatter.string(fromByteCount: app.size)
    }
}
