//
//  BookmarkTableViewCell.swift
//  Co-Alarm
//
//  Created by woogie on 2020/05/31.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import UIKit

class BookmarkTableViewCell: UITableViewCell {
    @IBOutlet weak var pinImageView: UIImageView!
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var remainLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
