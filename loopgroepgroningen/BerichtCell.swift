//
//  TableViewCell.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 16-06-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

class BerichtCell: UITableViewCell {
    
    // MARK: properties
    
    @IBOutlet weak var auteurLabel: UILabel!
    @IBOutlet weak var tijdstipLabel: UILabel!
    @IBOutlet weak var berichtTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
