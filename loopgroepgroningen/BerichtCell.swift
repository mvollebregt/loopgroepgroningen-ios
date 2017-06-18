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
    
    @IBOutlet weak var prikselView: UIView!
    @IBOutlet weak var auteurLabel: UILabel!
    @IBOutlet weak var tijdstipLabel: UILabel!
    @IBOutlet weak var berichtLabel: UILabel!
    
    private var dateFormatter = DateFormatter()
    private var _bericht : Bericht?

    var bericht : Bericht? {
        get {
            return _bericht
        }
        set(newBericht) {
            _bericht = newBericht;
            auteurLabel.text = _bericht!.auteur
            tijdstipLabel.text = dateFormatter.string(from: _bericht!.tijdstip!)
            berichtLabel.text = _bericht!.bericht
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        dateFormatter.dateFormat = "dd-MM hh:mm"
        prikselView.layer.cornerRadius = 6.0
        prikselView.layer.masksToBounds = true

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
