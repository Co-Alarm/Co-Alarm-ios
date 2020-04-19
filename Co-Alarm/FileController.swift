//
//  FileController.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/19.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import Foundation

class FileController {
    
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentDirectory.appendingPathComponent("bookmarkStores").appendingPathExtension("plist")
    
    static func saveBookmarkedStores(_ bookmarkedStores: [Store]) {
        let encodedBookmarkedStores = try? PropertyListEncoder().encode(bookmarkedStores)
        do {
            try encodedBookmarkedStores?.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("error")
        }
    }
    
    static func loadBookmarkedStores() -> [Store]? {
        guard let codedStores = try? Data(contentsOf: archiveURL) else {return nil}
        return try? PropertyListDecoder().decode(Array<Store>.self, from: codedStores)
    }
}
