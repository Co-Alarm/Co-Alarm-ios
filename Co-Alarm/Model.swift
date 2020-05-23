//
//  Model.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/04.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import UIKit
import MapKit

struct Store: Codable {
    let code: String
    let name: String
    let addr: String
    let lat: Double
    let lng: Double
    let stockAt: String?
    var remain: String?
    let createdAt: String?
    enum CodingKeys: String, CodingKey {
        case code
        case name
        case addr
        case lat
        case lng
        case stockAt = "stock_at"
        case remain = "remain_stat"
        case createdAt = "created_at"
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

struct Article: Codable {
    let title: String
    let link: String
    let description: String
}

struct News: Codable {
    let total: Int
    let start: Int
    let items: [Article]
}

//MKPointAnnotation 객체에 주소와 이미지 파일 이름을 담기 위해 자식클래스를 만듬
class CustomPointAnnotation: MKPointAnnotation {
    var code: String = ""
    var addr: String = ""
    var imageName: String = ""
    var stockAt: String? = ""
    var createdAt: String? = ""
    var remain: String? = ""
}
