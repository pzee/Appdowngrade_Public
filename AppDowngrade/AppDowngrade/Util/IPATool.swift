//
//  IPATool.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 19/10/2024.
//

// Heavily inspired by ipatool-py.
// https://github.com/NyaMisty/ipatool-py

import Foundation
import CommonCrypto
import Zip
import Alamofire
import RxSwift
import RxCocoa


extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

class SHA1 {
    static func hash(_ data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
    }
}

extension String {
    subscript (i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }

    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start..<end])
    }
}

typealias DownloadCompleteHandler = () -> Void
typealias ADBoolResultHandler = (Bool) -> Void

class StoreClient {
    var session: URLSession
    var appleId: String
    var password: String
    var guid: String?
    var accountName: String?
    var authHeaders: [String: String]?
    var authCookies: [HTTPCookie]?

    // 添加进度观察变量
    let downloadProgress = BehaviorRelay<Float>(value: 0.0)
    var downloadSpeed:Double = 0.0
    
    init(appleId: String, password: String) {
        session = URLSession.shared
        self.appleId = appleId
        self.password = password
        self.guid = nil
        self.accountName = nil
        self.authHeaders = nil
        self.authCookies = nil
    }

    func generateGuid(appleId: String) -> String {
        kk_print("Generating GUID")
        let DEFAULT_GUID = "000C2941396B"
        let GUID_DEFAULT_PREFIX = 2
        let GUID_SEED = "CAFEBABE"
        let GUID_POS = 10

        let h = SHA1.hash((GUID_SEED + appleId + GUID_SEED).data(using: .utf8)!).hexString
        let defaultPart = DEFAULT_GUID.prefix(GUID_DEFAULT_PREFIX)
        let hashPart = h[GUID_POS..<GUID_POS + (DEFAULT_GUID.count - GUID_DEFAULT_PREFIX)]
        let guid = (defaultPart + hashPart).uppercased()

        kk_print("Came up with GUID: \(guid)")
        return guid
    }

    func saveAuthInfo() -> Void {
        let authCookiesEnc1 = try! NSKeyedArchiver.archivedData(withRootObject: authCookies!, requiringSecureCoding: false)
        let authCookiesEnc = authCookiesEnc1.base64EncodedString()
        let out: [String: Any] = [
            "appleId": appleId,
            "password": password,
            "guid": guid ?? "",
            "accountName": accountName ?? "",
            "authHeaders": authHeaders ?? [:],
            "authCookies": authCookiesEnc
        ]
        let data = try! JSONSerialization.data(withJSONObject: out, options: [])
        let base64 = data.base64EncodedString()
        EncryptedKeychainWrapper.saveAuthInfo(base64: base64)
    }

    func tryLoadAuthInfo() -> Bool {
        if let base64 = EncryptedKeychainWrapper.loadAuthInfo() {
            let data = Data(base64Encoded: base64)!
            let out = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            appleId = out["appleId"] as! String
            password = out["password"] as! String
            guid = out["guid"] as? String
            accountName = out["accountName"] as? String
            authHeaders = out["authHeaders"] as? [String: String]
            let authCookiesEnc = out["authCookies"] as! String
            let authCookiesEnc1 = Data(base64Encoded: authCookiesEnc)!
//            authCookies = NSKeyedUnarchiver.unarchiveObject(with: authCookiesEnc1) as? [HTTPCookie]
            do {
                // 创建 NSKeyedUnarchiver 实例
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: authCookiesEnc1)
                // 设置为不需要安全编码，与归档时保持一致
                unarchiver.requiresSecureCoding = false
                
                // 从根对象解码
                authCookies = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [HTTPCookie]
                unarchiver.finishDecoding()
                
                // 使用解码后的 authCookies
            } catch {
                kk_print("解码失败: \(error)")
            }
            
            kk_print("Loaded auth info")
            return true
        }
        kk_print("No auth info found, need to authenticate")
        return false
    }

    func authenticate(requestCode: Bool = false,complete:@escaping ADBoolResultHandler)  {
        if self.guid == nil {
            self.guid = generateGuid(appleId: appleId)
        }

//        var req = [
//            "appleId": appleId,
//            "password": password,
//            "guid": guid!,
//            "rmp": "0",
//            "why": "signIn"
//        ]
        
        let req:[String:Any] = [
            "appleId": appleId,
            "attempt": requestCode ? 2 : 4,
            "createSession": true,
            "guid": guid ?? "",
            "password": password,
            "rmp": 0,
            "why": "signIn"
        ]
        
        
        let urlString: String = String(format: "https://auth.itunes.apple.com/auth/v1/native/fast?guid=%@",guid ?? "")
        //"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate")
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Accept": "*/*",
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent":"Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: req, options: [])
        let datatask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                kk_print("error 1 \(error.localizedDescription)")
                complete(false)
                return
            }
            if let response = response {
//                    kk_print("Response: \(response)")
                if let response = response as? HTTPURLResponse {
                    kk_print("New URL: \(response.url!)")
                    request.url = response.url
                }
            }
            if let data = data {
                do {
                    let resp = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
                    if resp["m-allowed"] as! Bool {
                        kk_print("Authentication successful")
                        let download_queue_info = resp["download-queue-info"] as! [String: Any]
                        let dsid = download_queue_info["dsid"] as! Int
                        let httpResp = response as! HTTPURLResponse
                        let storeFront = httpResp.value(forHTTPHeaderField: "x-set-apple-store-front")
                        kk_print("Store front: \(storeFront!)")
                        self.authHeaders = [
                            "X-Dsid": String(dsid),
                            "iCloud-Dsid": String(dsid),
                            "X-Apple-Store-Front": storeFront!,
                            "X-Token": resp["passwordToken"] as! String
                        ]
                        self.authCookies = self.session.configuration.httpCookieStorage?.cookies
                        let accountInfo = resp["accountInfo"] as! [String: Any]
                        let address = accountInfo["address"] as! [String: String]
                        self.accountName = address["firstName"]! + " " + address["lastName"]!
                        self.saveAuthInfo()
                        complete(true)
                    } else {
                        kk_print("Authentication failed: \(resp["customerMessage"] as! String)")
                        complete(false)
                    }
                } catch {
                    kk_print("Error: \(error)")
                    complete(false)
                }
            }
        }
        datatask.resume()
           
        
    }

    func volumeStoreDownloadProduct(appId: String, appVerId: String = "") -> [String: Any] {
        var req = [
            "creditDisplay": "",
            "guid": self.guid!,
            "salableAdamId": appId,
        ]
        if appVerId != "" {
            req["externalVersionId"] = appVerId
        }
        let url = URL(string: "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=\(self.guid!)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: req, options: [])
        kk_print("Setting headers")
        for (key, value) in self.authHeaders! {
            kk_print("Setting header \(key): \(value)")
            request.addValue(value, forHTTPHeaderField: key)
        }
        kk_print("Setting cookies")
        self.session.configuration.httpCookieStorage?.setCookies(self.authCookies!, for: url, mainDocumentURL: nil)

        var resp = [String: Any]()
        let datatask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                kk_print("error 2 \(error.localizedDescription)")
                return
            }
            if let data = data {
                do {
                    kk_print("Got response")
                    let resp1 = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
                    if resp1["cancel-purchase-batch"] != nil {
                        kk_print("Failed to download product: \(resp1["customerMessage"] as! String)")
                    }
                    resp = resp1
                } catch {
                    kk_print("Error: \(error)")
                }
            }
        }
        datatask.resume()
        while datatask.state != .completed {
            sleep(1)
        }
        kk_print("Got download response")
        return resp
    }

    func download(appId: String, appVer: String = "", isRedownload: Bool = false) -> [String: Any] {
        return self.volumeStoreDownloadProduct(appId: appId, appVerId: appVer)
    }

    func downloadToPath(url: String, path: String,complete:DownloadCompleteHandler?) -> Void {
        let destination: DownloadRequest.Destination = { _, _ in
            let fileURL = URL(fileURLWithPath: path)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        // 计算下载速度
        var lastBytes: Int64 = 0
        var lastTime = Date()

        AF.download(url, to: destination)
           .downloadProgress { progress in
               let percentage = Float(progress.fractionCompleted)
               self.downloadProgress.accept(percentage)
               
               // 计算下载速度
               let currentTime = Date()
               let timeInterval = currentTime.timeIntervalSince(lastTime)
               let bytesChange = progress.completedUnitCount - lastBytes
               
               if timeInterval >= 1.0 { // 每秒更新一次速度
                   let speed = Double(bytesChange) / timeInterval
                   let speedMB = speed / 1024.0 / 1024.0 // 转换为 MB/s
                   
                   self.downloadSpeed = speedMB
                   // 更新上次的值
                   lastBytes = progress.completedUnitCount
                   lastTime = currentTime
               }
           }
           .response { response in
               if let error = response.error {
                   kk_print("Download error: \(error.localizedDescription)")
               }
               kk_print("Downloaded to \(path)")
               complete?()
           }
        
    }
}

class IPATool {
    var session: URLSession
    var appleId: String
    var password: String
    var storeClient: StoreClient

    private let disposeBag = DisposeBag()
    // 添加进度观察变量
    let downloadProgress = BehaviorRelay<Float>(value: 0.0)
    
    var downloadSpeed:Double{
        return storeClient.downloadSpeed
    }
    
    init(appleId: String, password: String) {
        kk_print("init!")
        session = URLSession.shared
        self.appleId = appleId
        self.password = password
        storeClient = StoreClient(appleId: appleId, password: password)

        storeClient.downloadProgress.subscribe(onNext: {[weak self] progress in
        // 处理进度更新，progress 范围 0.0-1.0
            guard let `self` = self else {return}
            self.downloadProgress.accept(progress)
            
        }) .disposed(by: disposeBag)

    }


    func authenticate(requestCode: Bool = false,complete:@escaping ADBoolResultHandler)  {
        kk_print("Authenticating to iTunes Store...")
        if !storeClient.tryLoadAuthInfo() {
            storeClient.authenticate(requestCode: requestCode){result in
                complete(result)
            }
        } else {
            complete(true)
        }
    }

    func getVersionIDList(appId: String) -> [String] {
        kk_print("Retrieving download info for appId \(appId)")
        let downResp = storeClient.download(appId: appId, isRedownload: true)
        if downResp["songList"] == nil {
            kk_print("Failed to get app download info!")
            return []
        }
        let songList = downResp["songList"] as! [[String: Any]]
        if songList.count == 0 {
            kk_print("Failed to get app download info!")
            return []
        }
        let downInfo = songList[0]
        let metadata = downInfo["metadata"] as! [String: Any]
        let appVerIds = metadata["softwareVersionExternalIdentifiers"] as! [Int]
        kk_print("Got available version ids \(appVerIds)")
        return appVerIds.map { String($0) }
    }

    func downloadIPAForVersion(appId: String, appVerId: String,complete:@escaping (String)->(Void)) {
        kk_print("Downloading IPA for app \(appId) version \(appVerId)")
        let downResp = storeClient.download(appId: appId, appVer: appVerId)
        let songList = downResp["songList"] as! [[String: Any]]
        if songList.count == 0 {
            kk_print("Failed to get app download info!")
            complete("")
        }
        let downInfo = songList[0]
        let url = downInfo["URL"] as! String
        kk_print("Got download URL: \(url)")
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let path = tempDir.appendingPathComponent("app.ipa").path
        if fm.fileExists(atPath: path) {
            kk_print("Removing existing file at \(path)")
            try! fm.removeItem(atPath: path)
        }
        storeClient.downloadToPath(url: url, path: path){[weak self] in
            
            guard let `self` = self else {return}
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                Zip.addCustomFileExtension("ipa")

                let path3 = URL(string: path)!
                let fileExtension = path3.pathExtension
                let fileName = path3.lastPathComponent
                let directoryName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
                let documentsUrl = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationUrl = documentsUrl.appendingPathComponent(directoryName, isDirectory: true)
                if fm.fileExists(atPath: destinationUrl.path) {
                    kk_print("Removing existing folder at \(destinationUrl.path)")
                    try! fm.removeItem(at: destinationUrl)
                }
                
                let unzipDirectory = try? Zip.quickUnzipFile(URL(fileURLWithPath: path))
                guard let unzipDirectory = unzipDirectory else {
                    kk_print("Failed to unzip file!")
                    complete("")
                    return
                }
                var metadata = downInfo["metadata"] as! [String: Any]
                let metadataPath = unzipDirectory.appendingPathComponent("iTunesMetadata.plist").path
                metadata["apple-id"] = self.appleId
                metadata["userName"] = self.appleId
                _ = (metadata as NSDictionary).write(toFile: metadataPath, atomically: true)
                kk_print("Wrote iTunesMetadata.plist")
                var appContentDir = ""
                let payloadDir = unzipDirectory.appendingPathComponent("Payload")
                for entry in try! fm.contentsOfDirectory(atPath: payloadDir.path) {
                    if entry.hasSuffix(".app") {
                        kk_print("Found app content dir: \(entry)")
                        appContentDir = "Payload/" + entry
                        break
                    }
                }
                kk_print("Found app content dir: \(appContentDir)")
                let scManifestData = try! Data(contentsOf: unzipDirectory.appendingPathComponent(appContentDir).appendingPathComponent("SC_Info").appendingPathComponent("Manifest.plist"))
                let scManifest = try! PropertyListSerialization.propertyList(from: scManifestData, options: [], format: nil) as! [String: Any]
                let sinfsDict = downInfo["sinfs"] as! [[String: Any]]
                if let sinfPaths = scManifest["SinfPaths"] as? [String] {
                    for (i, sinfPath) in sinfPaths.enumerated() {
                        let sinfData = sinfsDict[i]["sinf"] as! Data
                        try! sinfData.write(to: unzipDirectory.appendingPathComponent(appContentDir).appendingPathComponent(sinfPath))
                        kk_print("Wrote sinf to \(sinfPath)")
                    }
                } else {
                    kk_print("Manifest.plist does not exist! Assuming it is an old app without one...")
                    let infoListData = try! Data(contentsOf: unzipDirectory.appendingPathComponent(appContentDir).appendingPathComponent("Info.plist"))
                    let infoList = try! PropertyListSerialization.propertyList(from: infoListData, options: [], format: nil) as! [String: Any]
                    let sinfPath = appContentDir + "/SC_Info/" + (infoList["CFBundleExecutable"] as! String) + ".sinf"
                    let sinfData = sinfsDict[0]["sinf"] as! Data
                    try! sinfData.write(to: unzipDirectory.appendingPathComponent(sinfPath))
                    kk_print("Wrote sinf to \(sinfPath)")
                }
                kk_print("Downloaded IPA to \(unzipDirectory.path)")
                complete(unzipDirectory.path)
            }
        }
        
    }
}

class EncryptedKeychainWrapper {
    static func getDBPath() -> URL {
        return AppTools.dbDocumentPath()
    }

    static func generateAndStoreKey() -> Void {
        self.deleteKey()
        kk_print("Generating key")
        
        // Generate a random key
        var keyData = Data(count: 32) // 256 bits
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        
        if result == errSecSuccess {
            kk_print("Generated key!")
            // Save the key to db directory
            let keyPath = getDBPath().appendingPathComponent("encryption_key").path
            FileManager.default.createFile(atPath: keyPath, contents: keyData, attributes: nil)
            kk_print("Saved key to db directory")
        } else {
            kk_print("Failed to generate key!!")
        }
    }

    static func deleteKey() -> Void {
        let keyPath = getDBPath().appendingPathComponent("encryption_key").path
        try? FileManager.default.removeItem(atPath: keyPath)
    }

    static func saveAuthInfo(base64: String) -> Void {
        let fm = FileManager.default
        let keyPath = getDBPath().appendingPathComponent("encryption_key").path
        
        guard fm.fileExists(atPath: keyPath),
              let keyData = fm.contents(atPath: keyPath) else {
            kk_print("Failed to get key!")
            return
        }
        
        kk_print("Got key!")
        
        // Simple XOR encryption (for demonstration)
        let inputData = base64.data(using: .utf8)!
        var encryptedData = Data(count: inputData.count)
        
        for i in 0..<inputData.count {
            let keyByte = keyData[i % keyData.count]
            let dataByte = inputData[i]
            encryptedData[i] = dataByte ^ keyByte
        }
        
        kk_print("Encrypted data")
        let path = getDBPath().appendingPathComponent("authinfo").path
        fm.createFile(atPath: path, contents: encryptedData, attributes: nil)
        kk_print("Saved encrypted auth info")
    }

    static func loadAuthInfo() -> String? {
        let fm = FileManager.default
        let authPath = getDBPath().appendingPathComponent("authinfo").path
        let keyPath = getDBPath().appendingPathComponent("encryption_key").path
        
        if !fm.fileExists(atPath: authPath) || !fm.fileExists(atPath: keyPath) {
            return nil
        }
        
        guard let encryptedData = fm.contents(atPath: authPath),
              let keyData = fm.contents(atPath: keyPath) else {
            kk_print("Failed to read data!")
            return nil
        }
        
        kk_print("Got key!")
        
        // Simple XOR decryption
        var decryptedData = Data(count: encryptedData.count)
        
        for i in 0..<encryptedData.count {
            let keyByte = keyData[i % keyData.count]
            let dataByte = encryptedData[i]
            decryptedData[i] = dataByte ^ keyByte
        }
        
        kk_print("Decrypted data")
        return String(data: decryptedData, encoding: .utf8)
    }

    static func deleteAuthInfo() -> Void {
        let path = getDBPath().appendingPathComponent("authinfo").path
        try? FileManager.default.removeItem(atPath: path)
    }

    static func hasAuthInfo() -> Bool {
        return loadAuthInfo() != nil
    }

    static func getAuthInfo() -> [String: Any]? {
        if let base64 = loadAuthInfo() {
            let data = Data(base64Encoded: base64)!
            let out = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return out
        }
        return nil
    }

    static func nuke() -> Void {
        deleteAuthInfo()
        deleteKey()
    }
}
