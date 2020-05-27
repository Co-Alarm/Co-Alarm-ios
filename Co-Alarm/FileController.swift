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
    //즐겨찾기된 약국을 저장하는 함수
    static func saveBookmarkedStores(_ bookmarkedStores: [Store]) {
        let encodedBookmarkedStores = try? PropertyListEncoder().encode(bookmarkedStores)
        do {
            try encodedBookmarkedStores?.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("error")
        }
    }
    
    // MARK: - loadBookmarkedStores
    //즐겨찾기된 약국을 불러오는 함수
    static func loadBookmarkedStores() -> [Store]? {
        guard let codedStores = try? Data(contentsOf: archiveURL) else {return nil}
        return try? PropertyListDecoder().decode(Array<Store>.self, from: codedStores)
    }
}
