//
//  NetworkController.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/04.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import Foundation

class NetworkController {
    
    static let sharedInstance = NetworkController()
    
    let storeBaseURL = URL(string: "https://8oi9s0nnth.apigw.ntruss.com/corona19-masks/v1")!
    let geoCodeBaseURL = URL(string: "https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode")!
    let newsBaseURL = URL(string: "https://openapi.naver.com/v1/search/news.json")!
    
    //마스크 판매 현황 api와 통신하여 데이터를 fetch하는 함수
    func fetchStores(lat: Double, lng: Double, delta: Int, completion: @escaping ([Store]?)->Void) {
        print(lat)
        print(lng)
        let initialStoresURL = storeBaseURL.appendingPathComponent("storesByGeo").appendingPathComponent("json")
        var components = URLComponents(url: initialStoresURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "lat", value: "\(lat)"), URLQueryItem(name: "lng", value: "\(lng)"), URLQueryItem(name: "delta", value: "\(delta)")]
        let storesURL = components.url!
        let task = URLSession.shared.dataTask(with: storesURL){(data, response, error) in
            let jsonDecoder = JSONDecoder()
            if let data = data, let result: Stores = try? jsonDecoder.decode(Stores.self, from: data) {
                completion(result.stores)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    //geocode api와 통신하여 데이터를 fetch하는 함수
    func fetchGeoCode(addr: String, completion: @escaping (Address?) -> Void) {
        var components = URLComponents(url: geoCodeBaseURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "query", value: addr)]
        let geoCodeURL = components.url!
        var request = URLRequest(url: geoCodeURL)
        request.httpMethod = "get"
        request.addValue("Qkv8Jc1qgrTIhxFExYIUr3bOxiuS0y0FMYuchIUJ", forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
        request.addValue("jm02wbuk63", forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        let task = URLSession.shared.dataTask(with: request) { data,response,error in
            let jsonDecoder = JSONDecoder()
            if let data = data, let result = try? jsonDecoder.decode(GeoCode.self, from: data) {
                if result.addresses.count > 0 {
                    completion(result.addresses[0])
                } else {
                    print("결과 없음")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    //news api와 통신하여 데이터를 fetch하는 함수
    func fetchNews(completion: @escaping ([Article]?) -> Void) {
        var components = URLComponents(url: newsBaseURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "query", value: "코로나 확진자"), URLQueryItem(name: "display", value: "50"), URLQueryItem(name: "sort", value: "date")]
        let newsURL = components.url!
        var request = URLRequest(url: newsURL)
        request.httpMethod = "get"
        request.addValue("kJ6OAbPoZHd734uwmESa", forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue("moTCMHPJm3", forHTTPHeaderField: "X-Naver-Client-Secret")
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            let jsonDecoder = JSONDecoder()
            if let data = data, let result = try? jsonDecoder.decode(News.self, from: data) {
                completion(result.items)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
}
