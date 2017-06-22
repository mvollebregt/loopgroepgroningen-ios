//
//  Bericht.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 17-06-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import Foundation

class Bericht {
    
    var bericht : String?
    var auteur : String?
    var tijdstip : String?
    
    public var description: String {
        var description = "{auteur:"
        description.append(auteur ?? "")
        description.append(", tijdstip: ")
        description.append(tijdstip ?? "")
        description.append(", bericht: ")
        description.append(bericht ?? "")
        description.append(")")
        return description;
    }
    
}
