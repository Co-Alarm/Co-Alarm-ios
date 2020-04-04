//
//  Model.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/04.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import Foundation

struct Store: Codable {
    let name: String
    let lat: Double
    let lng: Double
    let stockAt: String?
    let remain: String?
    enum CodingKeys: String, CodingKey {
        case name
        case lat
        case lng
        case stockAt = "stock_at"
        case remain = "remain_stat"
    }
}

struct Stores: Codable {
    let count: Int
    let stores: [Store]
}

struct Address: Codable {
    let x: String
    let y: String
}

struct GeoCode: Codable {
    let addresses: [Address]
}
