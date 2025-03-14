//
//  BaseViewController.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import SnapKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.addSubview(backgroundImageView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            // 设置约束
            self.backgroundImageView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(UIScreen.kk.navigationFullHeight)
                make.bottom.equalToSuperview().offset(-UIScreen.kk.tabbarFullHeight)
    //            make.edges.equalToSuperview()
            }
        })
        
//        self.backgroundImageView.image = UIImage(named: "home_bg")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func setupEmptyStateView(image:UIImage? = UIImage(systemName: "square.and.arrow.down"),
                             title:String =  kAD_No_IPA_Found.localized(),
                             detail:String = kAD_No_IPA_Found_Tip.localized()) {
        let emptyStateView = UIView()
        emptyStateView.tag = 100 // Tag for easy reference
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        
        // Create image view with system icon
        let imageView = UIImageView(image: image?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        emptyStateView.addSubview(imageView)
        
        // Create label
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemGray
        emptyStateView.addSubview(label)
        
        // Create description label
        let descriptionLabel = UILabel()
        descriptionLabel.text = detail
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .systemGray2
        descriptionLabel.numberOfLines = 0
        emptyStateView.addSubview(descriptionLabel)
        
        // Use SnapKit for layout with leading/trailing instead of left/right
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        
        label.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func createActionButton(title: String, icon: String, color: UIColor, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        
        // Create configuration instead of using deprecated properties
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = color.withAlphaComponent(0.1)
        config.baseForegroundColor = color
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        config.imagePlacement = .leading
        button.configuration = config
        
        button.layer.cornerRadius = 10
        
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        
        return button
    }
    
    //
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
}
