//
//  Downgrader.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 19/10/2024.
//

import Foundation
import UIKit
import Telegraph
import Zip
import SVProgressHUD
import Localize_Swift


func downgradeAppToVersion(appId: String, versionId: String, ipaTool: IPATool) {
   ipaTool.downloadIPAForVersion(appId: appId, appVerId: versionId){path in
        kk_print("IPA downloaded to \(path)")
       SVProgressHUD.show(withStatus: kAD_Auth_IPA.localized())
       DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
           SVProgressHUD.dismiss()
       }
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
       let contents = try! fm.contentsOfDirectory(atPath: path)
        kk_print("Contents: \(contents)")
        let destinationUrl = tempDir.appendingPathComponent("app.ipa")
        try? Zip.zipFiles(paths: contents.map { URL(fileURLWithPath: path).appendingPathComponent($0) }, zipFilePath: destinationUrl, password: nil, progress: nil)
        kk_print("IPA zipped to \(destinationUrl)")
        let path2 = URL(fileURLWithPath: path)
        var appDir = path2.appendingPathComponent("Payload")
        for file in try! fm.contentsOfDirectory(atPath: appDir.path) {
            if file.hasSuffix(".app") {
                kk_print("Found app: \(file)")
                appDir = appDir.appendingPathComponent(file)
                break
            }
        }
        let infoPlistPath = appDir.appendingPathComponent("Info.plist")
        let infoPlist = NSDictionary(contentsOf: infoPlistPath)!
        let appBundleId = infoPlist["CFBundleIdentifier"] as! String
        let appVersion = infoPlist["CFBundleShortVersionString"] as! String
        kk_print("appBundleId: \(appBundleId)")
        kk_print("appVersion: \(appVersion)")

        
        if fm.fileExists(atPath: destinationUrl.path) {
            var appName = infoPlist["CFBundleExecutable"] as? String
            if appName == nil || appName!.isEmpty{
                appName = infoPlist["CFBundleName"] as? String
            }
            if appName == nil || appName!.isEmpty{
                appName = infoPlist["CFBundleDisplayName"] as? String
            }
            let targetURL = AppTools.downloadDocumentPath().appendingPathComponent(String(format: "%@.ipa", appName ?? "App")).path
            try? fm.moveItem(atPath: destinationUrl.path, toPath: targetURL)
            try? fm.removeItem(at: destinationUrl)
           
            try? fm.removeItem(at: path2)
            
            let app = AppDetail()
            app.appName = appName ?? "App"
            app.bundleID = appBundleId
            app.version = appVersion
            app.displayName = infoPlist["CFBundleDisplayName"] as? String ?? ""
            
            // Get file size
            do {
                let attributes = try fm.attributesOfItem(atPath: targetURL)
                if let fileSize = attributes[.size] as? Int64 {
                    app.size = fileSize
                }
            } catch {
                print("Error getting file size: \(error)")
            }
            
            DataBaseManager.shared.insertApp(appDetail: app){_ in
                
            }
            SVProgressHUD.showSuccess(withStatus: kAD_AD_Auth_IPA_Success.localized())
        }
    }
}

// 新增通用方法来显示 UIAlertController
func presentAlert(_ alert: UIAlertController) {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
        rootViewController.present(alert, animated: true, completion: nil)
    }
}

func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    presentAlert(alert)
}

func getAllAppVersionIdsFromServer(appId: String, ipaTool: IPATool) {
    let serverURL = "https://apis.bilin.eu.org/history/"
    let url = URL(string: "\(serverURL)\(appId)")!
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            DispatchQueue.main.async {
                showAlert(title: kAD_Error.localized(), message: error.localizedDescription)
            }
            return
        }
        let json = try! JSONSerialization.jsonObject(with: data!) as! [String: Any]
        if let versionIds = json["data"] as? [Dictionary<String, Any>]{
            if versionIds.count == 0 {
                DispatchQueue.main.async {
                    showAlert(title: kAD_Error.localized(), message: kAD_No_Version_ID.localized())
                }
                return
            }
            DispatchQueue.main.async {
                let isiPad = UIDevice.current.userInterfaceIdiom == .pad
                let alert = UIAlertController(title: kAD_Select_Version.localized(), message: kAD_Select_Down_Version.localized(), preferredStyle: isiPad ? .alert : .actionSheet)
                for versionId in versionIds {
                    alert.addAction(UIAlertAction(title: "\(versionId["bundle_version"]!)", style: .default, handler: { _ in
                        downgradeAppToVersion(appId: appId, versionId: "\(versionId["external_identifier"]!)", ipaTool: ipaTool)
                    }))
                }
                alert.addAction(UIAlertAction(title: kAD_Cancel.localized(), style: .cancel, handler: nil))
                presentAlert(alert)
            }
        }else{
            DispatchQueue.main.async {
                showAlert(title: kAD_Error.localized(), message: kAD_Not_Found.localized())
            }
            
        }
        
    }
    task.resume()
}

func promptForVersionId(appId: String, versionIds: [String], ipaTool: IPATool) {
    let isiPad = UIDevice.current.userInterfaceIdiom == .pad
    let alert = UIAlertController(title: kAD_Input_ID_Placeholder.localized(), message: kAD_Select_Down_Version.localized(), preferredStyle: isiPad ? .alert : .actionSheet)
    for versionId in versionIds {
        alert.addAction(UIAlertAction(title: versionId, style: .default, handler: { _ in
            downgradeAppToVersion(appId: appId, versionId: versionId, ipaTool: ipaTool)
        }))
    }
    alert.addAction(UIAlertAction(title: kAD_Cancel.localized(), style: .cancel, handler: nil))
    presentAlert(alert)
}

func downgradeApp(appId: String, ipaTool: IPATool) {
    let versionIds = ipaTool.getVersionIDList(appId: appId)
    if versionIds.count == 0 {
        showAlert(title: kAD_Error.localized(), message: kAD_AD_No_Version_ID_1.localized())
        return
    }
    
    let isiPad = UIDevice.current.userInterfaceIdiom == .pad
    
    let alert = UIAlertController(title: kAD_Version_ID.localized(), message: kAD_Input_ID_Tip.localized(), preferredStyle: isiPad ? .alert : .actionSheet)
    alert.addAction(UIAlertAction(title: kAD_Manual.localized(), style: .default, handler: { _ in
        promptForVersionId(appId: appId, versionIds: versionIds, ipaTool: ipaTool)
    }))
    alert.addAction(UIAlertAction(title: kAD_Server.localized(), style: .default, handler: { _ in
        getAllAppVersionIdsFromServer(appId: appId, ipaTool: ipaTool)
    }))
    alert.addAction(UIAlertAction(title: kAD_Cancel.localized(), style: .cancel, handler: nil))
    presentAlert(alert)
}
