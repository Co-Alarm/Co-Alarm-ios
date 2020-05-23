//
//  BookmarkTableViewController.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/18.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import UIKit

class BookmarkTableViewController: UITableViewController {

    var bookmarkedStores: [Store] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let tempBookmarkedStores = FileController.loadBookmarkedStores() {
            DispatchQueue.main.async {
                self.bookmarkedStores = tempBookmarkedStores
                self.tableView.reloadData()
            }
        }
    }
    @IBAction func refreshButtonTapped(_ sender: Any) {
        for i in 0..<bookmarkedStores.count {
            NetworkController.sharedInstance.fetchStores(lat: self.bookmarkedStores[i].lat, lng: self.bookmarkedStores[i].lng, delta: 10) { (stores) in
                if let fetchedStores = stores {
                    if let fetchedStore = fetchedStores.first(where: {$0.code == self.bookmarkedStores[i].code}) {
                        DispatchQueue.main.async {
                            self.bookmarkedStores[i] = fetchedStore
                            print(self.bookmarkedStores[i])
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return bookmarkedStores.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookmark", for: indexPath)
        cell.textLabel?.text = bookmarkedStores[indexPath.row].name
        switch bookmarkedStores[indexPath.row].remain {
        case "plenty":
            cell.detailTextLabel?.text = "100개 이상"
        case "some":
            cell.detailTextLabel?.text = "30개 이상 100개 미만"
        case "few":
            cell.detailTextLabel?.text = "2개 이상 30개 미만"
        case "empty":
            cell.detailTextLabel?.text = "1개 이하"

        case "break":
            cell.detailTextLabel?.text = "판매중지"
        case "null":
            cell.detailTextLabel?.text = "정보 없음"
        default:
            break
        }
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let deletedStore = bookmarkedStores[indexPath.row]
            bookmarkedStores.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            FileController.saveBookmarkedStores(bookmarkedStores)
            
            //즐겨찾기된 약국을 지울 때 deleteBookmark라는 notification을 post
            NotificationCenter.default.post(name: Notification.Name("deleteBookmark"), object: nil, userInfo: ["deletedStore" : deletedStore])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

}

