//
//  DownloadViewController.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import Telegraph
import Zip
import SnapKit
import SwipeCellKit
import Localize_Swift
import SVProgressHUD

class ADDownloadViewController: BaseViewController {
    
    private var collectionView: UICollectionView!
    private var ipaFiles: [AppDetail] = []
    private var refreshControl: UIRefreshControl!

    private let itemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
    
    
    var server:Server = Server()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .kk_hex("#F7F7F7", alpha: 1.0)
        self.title = kAD_Apps.localized()
        
        setupCollectionView()
        loadIPAFiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data when view appears to refresh the list
        loadIPAFiles()
    }
    
    private func setupCollectionView() {
        // Create a flow layout for the collection view
        let layout = UICollectionViewFlowLayout()
        
        layout.scrollDirection = .vertical
        
        // Initialize collection view with the layout
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
//        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Register cell
        collectionView.register(ADAppListCell.self, forCellWithReuseIdentifier: AppListCellIdentifier)
        
        // Set delegates
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Add to view
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(UIScreen.kk.tabbarFullHeight)
            make.top.equalToSuperview().offset(UIScreen.kk.navigationFullHeight)
        }
        
        // Setup refresh control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refreshControl.tintColor = .systemGray2
        collectionView.refreshControl = refreshControl
        
        // Setup empty state view
        setupEmptyStateView()
    }
    
    @objc private func refreshData() {
        // Reload IPA files
        loadIPAFiles()
        
        // End refreshing after a short delay to provide visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.refreshControl.endRefreshing()
        }
    }
    
   
   //MARK: - operation
    
    private func loadIPAFiles() {
        DataBaseManager.shared.getAllApps { apps in
            self.ipaFiles = apps ?? []
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                
                // Show or hide empty state view based on ipaFiles count
                if let emptyStateView = self.view.viewWithTag(100) {
                    emptyStateView.isHidden = !self.ipaFiles.isEmpty ? true : false
                }
            }
        }
    }

    private func installIPA(app:AppDetail){
        // 对应用名称进行URL编码，确保中文字符能够正确处理
        
        if FileManager.default.fileExists(atPath: app.path) == false {
            SVProgressHUD.showError(withStatus: kAD_Not_Found.localized())
            DataBaseManager.shared.deleteApp(appName: app.appName) { result in
                if result {
                    self.loadIPAFiles()
                }
            }
            return
        }
        
        let encodedAppName = app.appName
        
        let finalURL = "https://api.palera.in/genPlist?bundleid=\(app.bundleID)&name=\(app.appName)&version=\(app.version)&fetchurl=http://127.0.0.1:9090/\(encodedAppName).ipa"
        let installURL = "itms-services://?action=download-manifest&url=" + finalURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    
        DispatchQueue.global(qos: .background).async {
            
            self.server.route(.GET, "\(encodedAppName).ipa", { _ in
                kk_print("Serving signed.ipa")
                let signedIPAData = try Data(contentsOf: URL(fileURLWithPath: app.path))
                return HTTPResponse(body: signedIPAData)
            })
    
            self.server.route(.GET, "install", { _ in
                kk_print("Serving install page")
                let installPage = """
                <script type="text/javascript">
                    window.location = "\(installURL)"
                </script>
                """
                return HTTPResponse(.ok, headers: ["Content-Type": "text/html"], content: installPage)
            })
            
            if !self.server.isRunning {
                do{
                    try self.server.start(port: 9090)
                    kk_print("Server not running, start listening")
                }catch _{
                    kk_print("Server start failed")
                }
            }else{
                kk_print("Server has started listening")
            }
            

            DispatchQueue.main.async {
                kk_print("Requesting app install")
                UIApplication.shared.open(URL(string: installURL)!,options: [:]) { result in
                    kk_print("open url result \(result)")
                }
            }
        }
    }
    


    private func confirmDelete(app: AppDetail) {
        let title = String(format: kAD_Delete_Tip.localized(), app.appName)
        let alertController = UIAlertController(
            title: title,
            message: kAD_Action_Undone.localized(),
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: kAD_Cancel.localized(), style: .cancel))
        alertController.addAction(UIAlertAction(title: kAD_Delete.localized(), style: .destructive) { [weak self] _ in
            self?.deleteIPA(app: app)
        })
        
        present(alertController, animated: true)
    }

    private func deleteIPA(app: AppDetail) {
        do {
            try FileManager.default.removeItem(atPath: app.path)
            
            // Delete from database if exists
            DataBaseManager.shared.deleteApp(appName: app.appName) { success in
                if success {
                    kk_print("App deleted from database successfully")
                }
            }
            
            // Refresh the collection view
            loadIPAFiles()
        } catch {
            kk_print("Error deleting file: \(error)")
            // Show error alert
            let message = String(format: kAD_Delete_Failed.localized(), error.localizedDescription)
            let errorAlert = UIAlertController(
                title: kAD_Error.localized(),
                message:message,
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: kAD_OK.localized(), style: .default))
            present(errorAlert, animated: true)
        }
    }

    private func shareIPA(app: AppDetail) {
        let fileURL = URL(fileURLWithPath: app.path)
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // For iPad, set the source view for the popover
        if let popoverController = activityViewController.popoverPresentationController {
            if let cell = collectionView.cellForItem(at: IndexPath(item: ipaFiles.firstIndex(where: { $0.appName == app.appName }) ?? 0, section: 0)) {
                popoverController.sourceView = cell
                popoverController.sourceRect = cell.bounds
            } else {
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }
        
        present(activityViewController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension ADDownloadViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ipaFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AppListCellIdentifier, for: indexPath) as! ADAppListCell
        
        let app = ipaFiles[indexPath.item]
        cell.configure(with: app)
        cell.delegate = self
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ADDownloadViewController: UICollectionViewDelegateFlowLayout ,UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.kk.screenWidth //min( UIScreen.kk.screenWidth, 375.0)
        let width = screenWidth
        let height = 60.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.top
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let selectedApp = ipaFiles[indexPath.item]
        
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider:nil, actionProvider: { [weak self] _ in
            // Create menu actions
            let installAction = UIAction(title: kAD_Install.localized(), image: UIImage(systemName: "arrow.down.app")) { _ in
                self?.installIPA(app: selectedApp)
            }
            
            let deleteAction = UIAction(title: kAD_Delete.localized(), image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self?.confirmDelete(app: selectedApp)
            }
            
            let shareAction = UIAction(title: kAD_Share.localized(), image: UIImage(systemName: "square.and.arrow.up")) { _ in
                self?.shareIPA(app: selectedApp)
            }
            
            // Return the menu
            return UIMenu(title: selectedApp.appName, children: [installAction, deleteAction, shareAction])
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedApp = ipaFiles[indexPath.item]
        self.installIPA(app: selectedApp)
    }
    
}



// Add this extension to handle popover presentation
extension ADDownloadViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Force popover style even on iPhone
    }
}

extension ADDownloadViewController: SwipeCollectionViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: kAD_Delete.localized()) {[weak self] action, indexPath in
            // handle action by updating model with deletion
            guard let `self` = self else {return}
            let app = self.ipaFiles[indexPath.item]
            self.confirmDelete(app: app)
        }
        let shareAction = SwipeAction(style: .default, title: kAD_Share.localized()){[weak self]action, indexPath in
            
            guard let `self` = self else {return}
            let app = self.ipaFiles[indexPath.item]
            self.shareIPA(app: app)
        }
        shareAction.backgroundColor = .systemGreen

        // customize the action appearance
        deleteAction.image = UIImage(systemName: "trash")
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        
        return [deleteAction,shareAction]
    }
}
