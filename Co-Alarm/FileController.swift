//
//  FileController.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/19.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import Foundation

//documentDirectory를 관리하는 클래스
class FileController {
    
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentDirectory.appendingPathComponent("bookmarkStores").appendingPathExtension("plist")
    
    // MARK: - saveBookmarkedStores
    //documentDirectory에 [Store] 저장
    static func saveBookmarkedStores(_ bookmarkedStores: [Store]) {
        //[Store]를 암호화
        let encodedBookmarkedStores = try? PropertyListEncoder().encode(bookmarkedStores)
        //documentDirectory에 write
        do {
            try encodedBookmarkedStores?.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("error")
        }
    }
    
    // MARK: - loadBookmarkedStores
    //documentDirectory에 저장된 [Store]를 load
    static func loadBookmarkedStores() -> [Store]? {
        //documentDirectory에서 암호화된 데이터를 가져옴
        guard let codedStores = try? Data(contentsOf: archiveURL) else {return nil}
        //복호화하여 리턴
        return try? PropertyListDecoder().decode(Array<Store>.self, from: codedStores)
    }
}
