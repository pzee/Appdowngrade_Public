//
//  HomeViewController.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD
import Localize_Swift

class HomeViewController: BaseViewController {

    var ipaTool:IPATool?
    var appleId:String = ""
    var password:String = ""
    var isAuthenticated:Bool = false
    var progressHUD:WaveProgressView?
    var isDownloading:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.addSubview(self.homeView)
        homeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.view)
            make.top.equalTo(self.view).offset(UIScreen.kk.navigationFullHeight)
        }
        homeView.backgroundColor = .kk_hex("#F7F7F7", alpha: 1.0)
        self.title = kAD_Home.localized()
        
        self.checkAuthentication()
        
        NotificationCenter.default.rx.notification(Notification.Name(loginSuccessNotification)).subscribe(onNext: { [weak self] _ in
            guard let `self` = self else {return}
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkAuthentication()
            }
            
        }).disposed(by: rx.disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    //MARK: -
    
    private func checkAuthentication() {
        let authInfo = EncryptedKeychainWrapper.getAuthInfo()
        if authInfo == nil {
            isAuthenticated = false
        }else {
            isAuthenticated = true
        }
        
        kk_print("Found \(isAuthenticated ? "auth" : "no auth") info in keychain")
        if isAuthenticated {
            if ipaTool != nil {
                return
            }
            guard let authInfo = authInfo else {
                kk_print("Failed to get auth info from keychain, logging out")
                isAuthenticated = false
                EncryptedKeychainWrapper.nuke()
                EncryptedKeychainWrapper.generateAndStoreKey()
                return
            }
            appleId = authInfo["appleId"]! as! String
            password = authInfo["password"]! as! String
            self.homeView.updateUserAppId(appleId: appleId)
            ipaTool = IPATool(appleId: appleId, password: password)
            ipaTool?.authenticate(complete: { result in
                kk_print("Re-authenticated \(result ? "successfully" : "unsuccessfully")")
            })
           
        } else {
            kk_print("No auth info found in keychain, setting up by generating a key in SEP")
            EncryptedKeychainWrapper.generateAndStoreKey()
            self.homeView.updateUserAppId(appleId: "")
        }
        self.homeView.updateLoginButtonState(isLogin: isAuthenticated)
    }
    
    
    
    
    //MARK: -
    
    lazy var homeView: ADHomeView = {
        let view = ADHomeView()
        view.delegate = self
        return view
    }()
}

extension HomeViewController:ADHomeViewDelegate{
    func homeViewDidClickButton(_ sender: ADHomeView, type: ADHomeViewType) {
        switch type {
        case .Login:
            toLoginViewController()
            break
        case .Logout:
            self.logout()
            break
        case.Downgrade:
            self.downgrade()
        }
    
    }
    
    private func toLoginViewController() {
        let loginViewController = ADLoginViewController()
        self.present(loginViewController, animated: true, completion: {
            
        })
    }
    
    private func logout() {
        isAuthenticated = false
        ipaTool = nil
        EncryptedKeychainWrapper.nuke()
        EncryptedKeychainWrapper.generateAndStoreKey()
        self.homeView.updateLoginButtonState(isLogin: isAuthenticated)
        self.homeView.updateUserAppId(appleId:"")
    }
    
    private func downgrade() {
        view.endEditing(true)
        if isDownloading {
            SVProgressHUD.showError(withStatus: kAD_Downing.localized())
            return
        }
        let appLink = self.homeView.link ?? ""
        if appLink.isEmpty {
            return
        }
        var appLinkParsed = appLink
        appLinkParsed = appLinkParsed.components(separatedBy: "id").last ?? ""
        for char in appLinkParsed {
            if !char.isNumber {
                appLinkParsed = String(appLinkParsed.prefix(upTo: appLinkParsed.firstIndex(of: char)!))
                break
            }
        }
        if appLinkParsed.isEmpty {
            SVProgressHUD.showError(withStatus: kAD_Invalid_App_Link.localized())
            return
        }
        kk_print("App ID: \(appLinkParsed)")
        guard let ipaTool = ipaTool else {
            SVProgressHUD.showError(withStatus: kAD_Not_Auth.localized())
            return
        }
       
        downgradeApp(appId: appLinkParsed, ipaTool: ipaTool)
        
        ipaTool.downloadProgress.accept(0.0)
        ipaTool.downloadProgress.subscribe(onNext: {[weak self,weak ipaTool] progress in
        // 处理进度更新，progress 范围 0.0-1.0
            guard let `self` = self else {return}
            guard let ipaTool = ipaTool else {return}
            if progress > 0.0 {
                DispatchQueue.main.async {
                    if self.progressHUD == nil {
                        UIApplication.shared.isIdleTimerDisabled = true  // 保持屏幕常亮
                        self.progressHUD = WaveProgressView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                        self.progressHUD?.center = self.view.center
                        self.progressHUD?.alpha = 0
                        self.view.addSubview(self.progressHUD!)
                        UIView.animate(withDuration: 0.1) {
                            self.progressHUD?.alpha = 1.0
                        }
                        self.isDownloading = true
                    }
                    
                    self.progressHUD?.progress = CGFloat(progress)
                    self.progressHUD?.netspeed = ipaTool.downloadSpeed
                }
            }
            if progress >= 1.0 {
                DispatchQueue.main.async {
                    self.progressHUD?.progress = CGFloat(progress)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.isIdleTimerDisabled = false  // 恢复正常的屏幕超时设置
                        UIView.animate(withDuration: 0.3) {
                            self.progressHUD?.alpha = 0
                        }completion: { result in
                            self.progressHUD?.removeFromSuperview()
                            self.progressHUD = nil
                            self.isDownloading = false
                        }
                    }
                }
            }
        }) .disposed(by: rx.disposeBag)
    }
}
