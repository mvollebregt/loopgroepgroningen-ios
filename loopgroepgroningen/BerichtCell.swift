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
    @IBOutlet weak var berichtLabel: UITextView!
    
    private var dateFormatter = DateFormatter()
    private var _bericht : BerichtMO?

    var bericht : BerichtMO? {
        get {
            return _bericht
        }
        set(newBericht) {
            _bericht = newBericht;
            auteurLabel.text = _bericht!.auteur
            tijdstipLabel.text = _bericht!.tijdstip! //dateFormatter.string(from: _bericht!.tijdstip!)
            berichtLabel.text = _bericht!.berichttekst
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
