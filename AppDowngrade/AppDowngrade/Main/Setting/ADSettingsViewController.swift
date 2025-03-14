//
//  ADSettingsViewController.swift
//  AppDowngrade
//
//  Created by dev on 3/14/25.
//

import UIKit
import SnapKit
import Localize_Swift


class ADSettingsViewController: BaseViewController {
    
    // MARK: - Properties
    private var collectionView: UICollectionView!
    private var dataSource: [ADSettingsSection] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = kAD_Settings.localized()
        setupData()
        setupCollectionView()
    }
    
    // MARK: - Setup
    private func setupData() {
        // 第一个 section - 基于项目
        let projectItems = [
            ADSettingsItem(title: "ipatool.js", icon: UIImage(systemName: "link"), link: "https://github.com/wf021325/ipatool.js"),
            ADSettingsItem(title: "MuffinStoreJailed-Public", icon: UIImage(systemName: "link"),link:"https://github.com/mineek/MuffinStoreJailed-Public")
        ]
        
        dataSource = [
            ADSettingsSection(title: kAD_Base_Project.localized(), items: projectItems)
        ]
    }
    
    private func setupCollectionView() {
        // 使用 FlowLayout 而不是 CompositionalLayout
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 40)
        
        // 初始化 CollectionView
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .kk_hex("#F7F7F7", alpha: 1.0)
        view.addSubview(collectionView)
        
        // 使用 SnapKit 设置约束
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // 注册 Cell 和 Header
        collectionView.register(ADSettingsCell.self, forCellWithReuseIdentifier: ADSettingsCell.identifier)
        collectionView.register(ADSettingsHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                              withReuseIdentifier: ADSettingsHeaderView.identifier)
        
        // 设置代理
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
}

// MARK: - UICollectionViewDataSource
extension ADSettingsViewController: UICollectionViewDataSource ,UICollectionViewDelegateFlowLayout{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ADSettingsCell.identifier, for: indexPath) as? ADSettingsCell else {
            return UICollectionViewCell()
        }
        
        let item = dataSource[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ADSettingsHeaderView.identifier,
                for: indexPath) as? ADSettingsHeaderView else {
                return UICollectionReusableView()
            }
            
            let title = dataSource[indexPath.section].title
            headerView.configure(with: title)
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func  collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width - 32, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.bounds.width, height: 40)
    }
    
    
}

// MARK: - UICollectionViewDelegate
extension ADSettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        // 执行点击操作
        let item = dataSource[indexPath.section].items[indexPath.row]
        guard let url = URL(string: item.link) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
