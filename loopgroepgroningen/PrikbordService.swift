//
//  PrikbordService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 22-06-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import Foundation

class PrikbordService {
    
    static func getBerichten() {
        
        let url = URL(string: "http://www.loopgroepgroningen.nl/index.php/prikbord")
        
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            
            let parser = TFHpple.init(htmlData: data);
            let elements = parser?.search(withXPathQuery: "//div[@class='easy_frame']") as! [TFHppleElement]?;
            
            var berichten = [Bericht]()
            for element in elements! {
                let bericht = mapToBericht(element: element)
                berichten.append(bericht)
                print(bericht.description)
            }
        }
        task.resume()
    }
    
    static func mapToBericht(element: TFHppleElement) -> Bericht {
        let bericht = Bericht()
        bericht.auteur = getText(fromElement:element, withXPathQuery: "//*[@class='easy_big']");
        bericht.tijdstip = getText(fromElement:element, withXPathQuery: "//*[@class='easy_small']");
        bericht.bericht = ""
        
        let berichtElements = element.search(withXPathQuery: "//*[@class='easy_content']/node()") as! [TFHppleElement]?
        
        for contentElement in berichtElements! {
            if (contentElement.isTextNode()) {
                bericht.bericht!.append(contentElement.content)
            } else {
                bericht.bericht!.append("\n");
            }
        }
        return bericht

    }
    
    static func getText(fromElement: TFHppleElement, withXPathQuery: String) -> String {
        let auteurElements = fromElement.search(withXPathQuery: withXPathQuery) as! [TFHppleElement]?
        if (auteurElements!.count > 0) {
            return auteurElements![0].content
        }
        return "";
        
    }
    
}
