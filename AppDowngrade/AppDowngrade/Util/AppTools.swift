//
//  AppTools.swift
//  AppDowngrade
//
//  Created by dev on 3/10/25.
//

import UIKit

class AppTools: NSObject {
    static func dbDocumentPath() -> URL {
        let fm = FileManager.default
        let dbPath = fm.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("db")
        // Create db directory if it doesn't exist
        if !fm.fileExists(atPath: dbPath.path) {
            try? fm.createDirectory(at: dbPath, withIntermediateDirectories: true)
        }
        return dbPath
    }
    static func downloadDocumentPath() -> URL {
        let fm = FileManager.default
        let downloadPath = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("download")
        // Create download directory if it doesn't exist
        if !fm.fileExists(atPath: downloadPath.path) {
            try? fm.createDirectory(at: downloadPath, withIntermediateDirectories: true)
        }
        return downloadPath
    }

    static func clearDownloadDirectory() -> Bool {
        let downloadPath = self.downloadDocumentPath()
        let fm = FileManager.default
        
        do {
            try fm .removeItem(atPath: downloadPath.path)
            return true
        } catch {
            kk_print("Failed to clear download directory: \(error)")
            return false
        }
    }
}
