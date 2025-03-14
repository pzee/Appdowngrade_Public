//
//  LoginViewController.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import SnapKit
import SVProgressHUD

let loginSuccessNotification:String = "loginSuccessNotification"

class ADLoginViewController: BaseViewController {

    var ipaTool:IPATool?
    var isAuthenticated:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.addSubview(loginView)
        loginView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loginView.loginBlock = { [weak self] in
            guard let `self` = self else {return}
            self.login()
        }
    }
    
    //MARK: - func
    private func login() {
        let appleId = loginView.appleId
        let password = loginView.password
        let code = loginView.code
        
        if appleId.isEmpty || password.isEmpty {
            
            return
        }
        if code.isEmpty {
            // we can just try to log in and it'll request a code, very scuffed tho.
            ipaTool = IPATool(appleId: appleId, password: password)
            SVProgressHUD.show()
            ipaTool?.authenticate(requestCode: true){[weak self] ret in
                kk_print("result \(String(describing: ret))")
                guard let `self` = self else {return}
                if ret == true {
                    SVProgressHUD.dismiss(withDelay: 0.2)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.dismiss(animated: true)
                        NotificationCenter.default.post(name: Notification.Name(loginSuccessNotification), object: nil)
                    }
                }else{
                    SVProgressHUD.showError(withStatus: "login failed")
                }
            }
            
            
            return
        }
        let finalPassword = password + code
        ipaTool = IPATool(appleId: appleId, password: finalPassword)
        SVProgressHUD.show()
        ipaTool?.authenticate(){[weak self] ret in
            guard let `self` = self else {return}
            self.isAuthenticated = ret
            if ret == true {
                SVProgressHUD.dismiss(withDelay: 0.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dismiss(animated: true)
                    NotificationCenter.default.post(name: Notification.Name(loginSuccessNotification), object: nil)
                }
            }else{
                SVProgressHUD.showError(withStatus: "login failed")
            }
        }
        
        
    }
    
    //MARK: - lazy
    
    lazy var loginView: ADLoginView = {
        let view = ADLoginView()
        return view
    }()

}
