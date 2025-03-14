//
//  DBUtil.swift
//  AppDowngrade
//
//  Created by dev on 3/6/25.
//

import UIKit
import FMDB

class DataBaseManager: NSObject {
    
    static let shared = DataBaseManager()
    
    private var dbQueue: FMDatabaseQueue?
    private let dbName = "appDowngrade.sqlite"
    private let tableName = "AppDetail"
    
    override init() {
        super.init()
        setupDatabase()
    }
    

    private func setupDatabase() {
//        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbPath = AppTools.dbDocumentPath().appendingPathComponent(dbName).path
        
        dbQueue = FMDatabaseQueue(path: dbPath)
        
        createTable()
        
    }
    
    private func createTable() {
        dbQueue?.inDatabase { db in
            do {
                try db.executeUpdate("""
                    CREATE TABLE IF NOT EXISTS \(tableName) (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        appName TEXT NOT NULL UNIQUE,
                        version TEXT NOT NULL,
                        bundleID TEXT NOT NULL,
                        displayName TEXT
                    )
                """, values: nil)
                kk_print("Table created successfully")
            } catch {
                kk_print("Failed to create table: \(error.localizedDescription)")
            }
            self.upgradeDatabaseIfNeeded(db: db)
        }
    }
    
    private func getDatabaseVersion(db: FMDatabase) -> Int {
        do {
            let resultSet = try db.executeQuery("PRAGMA user_version", values: nil)
            if resultSet.next() {
                return Int(resultSet.int(forColumnIndex: 0))
            }
        } catch {
            kk_print("Failed to get database version: \(error.localizedDescription)")
        }
        return 0
    }

    private func setDatabaseVersion(db: FMDatabase, version: Int) {
        do {
            try db.executeUpdate("PRAGMA user_version = \(version)", values: nil)
        } catch {
            kk_print("Failed to set database version: \(error.localizedDescription)")
        }
    }
    
    private func upgradeDatabaseIfNeeded(db: FMDatabase) {
        let currentVersion = getDatabaseVersion(db: db)
        let targetVersion = 2 // 目标版本号，每次升级时递增

        if currentVersion < targetVersion {
            do {
                // 更新数据库版本
                setDatabaseVersion(db: db, version: targetVersion)
                // 增加新字段
                try db.executeUpdate("ALTER TABLE \(tableName) ADD COLUMN size LONG", values: nil)
                
                kk_print("Database upgraded to version \(targetVersion)")
            } catch {
                kk_print("Failed to upgrade database: \(error.localizedDescription)")
            }
        }
    }

    

    
    // MARK: - CRUD Operations
    
    // 添加应用信息（如果已存在则更新）
    func insertApp(appDetail: AppDetail, completion: @escaping (Bool) -> Void) {
        // 使用 inTransaction 而不是嵌套的 inDatabase 调用
        dbQueue?.inTransaction { db, rollback in
            do {
                // 先检查是否已存在
                let resultSet = try db.executeQuery("SELECT * FROM \(self.tableName) WHERE appName = ?", values: [appDetail.appName])
                
                if resultSet.next() {
                    // 已存在，执行更新
                    try db.executeUpdate("""
                        UPDATE \(self.tableName) 
                        SET version = ?, bundleID = ?,displayName = ?,size = ?
                        WHERE appName = ?
                    """, values: [appDetail.version, appDetail.bundleID,appDetail.displayName, appDetail.appName,appDetail.size])
                } else {
                    // 不存在，执行插入
                    try db.executeUpdate("""
                        INSERT INTO \(self.tableName) (appName, version, bundleID,displayName,size)
                        VALUES (?, ?, ?,?,?)
                    """, values: [appDetail.appName, appDetail.version, appDetail.bundleID,appDetail.displayName,appDetail.size])
                }
                completion(true)
            } catch {
                kk_print("Failed to insert/update app: \(error.localizedDescription)")
                rollback.pointee = true
                completion(false)
            }
        }
    }
    
    // 删除应用信息
    func deleteApp(bundleID: String, completion: @escaping (Bool) -> Void) {
        dbQueue?.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(tableName) WHERE bundleID = ?", values: [bundleID])
                completion(true)
            } catch {
                kk_print("Failed to delete app: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // 根据 appName 删除应用信息
    func deleteApp(appName: String, completion: @escaping (Bool) -> Void) {
        dbQueue?.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(tableName) WHERE appName = ?", values: [appName])
                completion(true)
            } catch {
                kk_print("Failed to delete app: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // 更新应用信息
    func updateApp(appDetail: AppDetail, completion: @escaping (Bool) -> Void) {
        dbQueue?.inDatabase { db in
            do {
                try db.executeUpdate("""
                    UPDATE \(tableName) 
                    SET version = ?, bundleID = ?,displayName = ?,size = ?
                    WHERE appName = ?
                """, values: [appDetail.version, appDetail.bundleID,appDetail.displayName, appDetail.appName,appDetail.size])
                completion(true)
            } catch {
                kk_print("Failed to update app: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // 查询所有应用信息
    func getAllApps(completion: @escaping ([AppDetail]?) -> Void) {
        var appDetails: [AppDetail] = []
        
        dbQueue?.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * FROM \(tableName)", values: nil)
                
                while resultSet.next() {
                    let appDetail = AppDetail()
                    appDetail.appName = resultSet.string(forColumn: "appName") ?? ""
                    appDetail.version = resultSet.string(forColumn: "version") ?? ""
                    appDetail.bundleID = resultSet.string(forColumn: "bundleID") ?? ""
                    appDetail.displayName = resultSet.string(forColumn: "displayName") ?? ""
                    appDetail.path = AppTools.downloadDocumentPath().appendingPathComponent("\(appDetail.appName).ipa").path
                    appDetail.size = Int64(resultSet.long(forColumn: "size"))
                    appDetails.append(appDetail)
                }
                
                completion(appDetails)
            } catch {
                kk_print("Failed to fetch apps: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    // 根据 bundleID 查询应用信息
    func getApp(bundleID: String, completion: @escaping (AppDetail?) -> Void) {
        dbQueue?.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * FROM \(tableName) WHERE bundleID = ?", values: [bundleID])
                
                if resultSet.next() {
                    let appDetail = AppDetail()
                    appDetail.appName = resultSet.string(forColumn: "appName") ?? ""
                    appDetail.version = resultSet.string(forColumn: "version") ?? ""
                    appDetail.bundleID = resultSet.string(forColumn: "bundleID") ?? ""
                    appDetail.displayName = resultSet.string(forColumn: "displayName") ?? ""
                    appDetail.size = Int64(resultSet.long(forColumn: "size"))
                    completion(appDetail)
                } else {
                    completion(nil)
                }
            } catch {
                kk_print("Failed to fetch app: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    // 根据 appName 查询应用信息
    func getApp(appName: String, completion: @escaping (AppDetail?) -> Void) {
        dbQueue?.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * FROM \(tableName) WHERE appName = ?", values: [appName])
                
                if resultSet.next() {
                    let appDetail = AppDetail()
                    appDetail.appName = resultSet.string(forColumn: "appName") ?? ""
                    appDetail.version = resultSet.string(forColumn: "version") ?? ""
                    appDetail.bundleID = resultSet.string(forColumn: "bundleID") ?? ""
                    appDetail.displayName = resultSet.string(forColumn: "displayName") ?? ""
                    appDetail.size = Int64(resultSet.long(forColumn: "size"))
                    completion(appDetail)
                } else {
                    completion(nil)
                }
            } catch {
                kk_print("Failed to fetch app: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    // 删除整个表
    func dropTable(completion: @escaping (Bool) -> Void) {
        dbQueue?.inDatabase { db in
            do {
                try db.executeUpdate("DROP TABLE IF EXISTS \(tableName)", values: nil)
                kk_print("Table dropped successfully")
                completion(true)
            } catch {
                kk_print("Failed to drop table: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
}
