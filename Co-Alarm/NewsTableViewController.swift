//
//  NewsTableViewController.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/11.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import UIKit
import SafariServices

class NewsTableViewController: UITableViewController {

    var articles: [Article] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //뉴스 api에서 데이터를 fetch
        NetworkController.sharedInstance.fetchNews { (articles) in
            if let articles = articles {
                self.articles = articles
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    //cell의 개수 동적으로 설정
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }

    //각 cell을 동적으로 설정
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "articleCell", for: indexPath)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20)
        //뉴스 기사의 제목이 HTML형식이어서 String으로 바꿔줌
        cell.textLabel?.text = try? self.articles[indexPath.row].title.strippingHTML()
        return cell
    }
    
    //cell을 눌렀을 때의 동작
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let url = URL(string: self.articles[indexPath.row].link) else {return}
        //SFSafariViewController를 이용하여 기사에 대한 링크 페이지를 띄움
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    //cell의 높이 설정
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

//HTML 형식을 String 형식으로 바꿔주는 함수를 추가
extension String {
    func strippingHTML() throws -> String? {
        if isEmpty {
            return nil
        }
        if let data = data(using: .utf8) {
            let attributedString = try NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html, .characterEncoding : String.Encoding.utf8.rawValue], documentAttributes: nil)
            let string = attributedString.string
            return string
        }
        return nil
    }
}
